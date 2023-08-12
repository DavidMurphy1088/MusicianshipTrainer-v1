import Foundation
import SwiftJWT
import Alamofire

enum OAuthCallType {
    case file
    case filesInFolder
    case googleDoc
}

enum RequestStatus {
    case success
    case waiting
    case failed
}

class DataRequest {
    var callType:OAuthCallType
    var id:String
    var targetExampleKey: String?
    var url:String?
    var accessToken:String?
    var context:String
    
    init(callType:OAuthCallType, id:String, context:String, targetExampleKey:String?) {
        self.callType = callType
        self.id = id
        self.targetExampleKey = targetExampleKey
        self.context = context
    }
}

class DataCache {
    private var dataCache:[String:Data?] = [:]
    private let enabled = false
    
    enum CachedType {
        case fromMemory
        case fromDefaults
    }
    
    func getData(key: String) -> (CachedType, Data?) {
        if !enabled {
            return (.fromDefaults, nil)
        }
        else {
            if let data = self.dataCache[key] {
                return (.fromMemory, data)
            }
            else {
                let data = UserDefaults.standard.data(forKey: key)
                if let data = data {
                    return (.fromDefaults, data)
                }
                else {
                    return (.fromDefaults, nil)
                }
            }
        }
    }
    
    func setData(key:String, data:Data) {
        self.dataCache[key] = data
        UserDefaults.standard.set(data, forKey: key)
    }
}

class GoogleAPI {
    static let shared = GoogleAPI()
    let dataCache = DataCache()
    
    let logger = Logger.logger
    
    private init() {
    }
    
    private func getAPIBundleData(key:String) -> String? {
        var data:String? = nil
        let pListName = "GoogleAPI"
        if let path = Bundle.main.path(forResource: pListName, ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            data = dict[key] as? String
            return data
        }
        guard data != nil else {
            logger.reportError(self, "Cannot find key \(key) in \(pListName).plist")
            return nil
        }
        return nil
    }
    
    func getExampleSheet(onDone: @escaping (_ status:RequestStatus, _ data:Data?) -> Void) {
        let examplesSheetKey:String? = getAPIBundleData(key: "ContentSheetID")
        //let examplesSheetKey:String? = getAPIBundleData(key: "ContentSheetID_TEST")
        
        if let examplesSheetKey = examplesSheetKey {
            let request = DataRequest(callType: .file, id: examplesSheetKey, context: "getExampleSheet", targetExampleKey: nil)
            var url:String
            url = "https://sheets.googleapis.com/v4/spreadsheets/"
            url +=  request.id
            url += "/values/Sheet1"
            //var request = request
            request.url = url
            getByAPI(request: request) {status,data in
                onDone(.success, data)
            }
        }
        else {
            logger.reportError(self, "Cannot find example sheet id")
            onDone(.failed, nil)
        }
    }

    ///Call a Google Drive API (sheets etc) using an API key. Note that this does not require an OAuth2 token request.
    ///Data accessed via an API key only is regarded as less senstive by Google than data in a Google doc that requires an OAuth token
    
    private func getByAPI(request:DataRequest, onDone: @escaping (_ status:RequestStatus, _ data:Data?) -> Void) {
        
        if let key = request.targetExampleKey {
            let (cachedType, cachedData) = dataCache.getData(key: key)
            if let data = cachedData {
                onDone(.success, cachedData)
                if cachedType == .fromMemory {
                    
                    return
                }
                else {
                    //continue loading below to reload memory cache if data changed in cloud
                }
            }
        }
        
        let apiKey:String? = getAPIBundleData(key: "APIKey")
        guard let apiKey = apiKey, let url = request.url else {
            logger.reportError(self, "Cannot find API key")
            onDone(.failed, nil)
            return
        }
        let urlWithKey = url + "?key=\(apiKey)"
        guard let url = URL(string: urlWithKey) else {
            logger.reportError(self, "Sheets, Invalid url \(url)")
            onDone(.failed, nil)
            return
        }
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                self.logger.reportError(self, "DataTask Error \(error.localizedDescription)")
                onDone(.failed, nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 200 {
                        guard let responseData = (responseString!).data(using: .utf8) else {
                            self.logger.reportError(self, "Invalid JSON data")
                            onDone(.failed, nil)
                            return
                        }
                        if let key = request.targetExampleKey {
                            self.dataCache.setData(key: key, data: data)
                        }
                        onDone(.success, data)
                    }
                    else {
                        self.logger.reportError(self, "HTTP response code \(httpResponse.statusCode) \(responseString ?? "")")
                        onDone(.failed, nil)
                    }
                }
                else {
                    self.logger.reportError(self, "HTTP response, no data")
                    onDone(.failed, nil)
                }
            }
        }
        
        task.resume()
    }
    
    ///======================= OAuth Calls ======================
    ///OAuth calls require that first an access key is granted. OAuth calls do not use the API key.
    ///OAuth authorization is managed by creating a Service Account in the Google Workspace and then generating a key for it
    ///The generated key is used to make the signed (by JWT) access token request

    func getDocumentByName(name:String, onDone: @escaping (_ status:RequestStatus, _ document:String?) -> Void) {
        let (cachedType, data) = dataCache.getData(key: name)
        if let data = data {
            if let document = String(data: data, encoding: .utf8) {
                onDone(.success, document)
                if cachedType == .fromMemory {
                    return
                }
            }
        }
        

        let folderId = getAPIBundleData(key: "GoogleDriveDataFolderID")
        guard let folderId = folderId else {
            self.logger.reportError(self, "No folder Id")
            return
        }
        
        let request = DataRequest(callType: .filesInFolder, id: folderId, context: "getDocumentByName.filesInFolder:\(name)", targetExampleKey: nil)
        
        getDataByID(request: request) { status, data in
            let fileId = self.getFileIDFromName(name:name, data: data) //{status, data  in
            guard let fileId = fileId else {
                self.logger.reportError(self, "File name not found, name:[\(name)]")
                onDone(.failed, nil)
                return
            }
            //https://docs.google.com/document/d/1WMW0twPTy0GpKXhlpiFjo-LO2YkDNnmPyp2UYrvXItU/edit?usp=sharing
            let request = DataRequest(callType: .googleDoc, id: fileId, context: "getDocumentByName.readDocument:\(name)", targetExampleKey: nil)
            self.getDataByID(request: request) { status, data in
                if let data = data {
                    struct Document: Codable {
                        let body: Body
                    }

                    struct Body: Codable {
                        let content: [Content]
                    }

                    struct Content: Codable {
                        let paragraph: Paragraph?
                    }
                    
                    struct Paragraph: Codable {
                        let elements: [Element]
                    }
                                            
                    struct Element: Codable {
                        let textRun: TextRun
                    }
                    
                    struct TextRun: Codable {
                        let content: String
                    }

                    do {
                        let decoder = JSONDecoder()
                        let document = try decoder.decode(Document.self, from: data)
                        var textContent = ""
                        for content in document.body.content {
                            if let paragraph = content.paragraph {
                                for element in paragraph.elements {
                                    textContent += element.textRun.content
                                }
                            }
                        }
                        let data = textContent.data(using: .utf8)
                        if let data = data {
                            self.dataCache.setData(key: name, data: data)
                            //self.dataCache[name] = data
                        }
                        onDone(.success, textContent)
                    }
                    catch let error {
                        let str = String(data: data, encoding: .utf8)
                        self.logger.reportError(self, "Cannot parse \(name) \(error.localizedDescription) data:\(str ?? "")")
                        onDone(.failed, nil)
                    }
                }
            }
        }
    }
            
    func getFileIDFromName(name:String, data:Data?) -> String? {
        guard let data = data else {
            self.logger.reportError(self, "No data for file list")
            return nil
        }
        struct GoogleFile : Codable {
            let name: String
            let id: String
            let parents: [String]?
        }
        struct FileSearch : Codable {
            let kind:String
            let files:[GoogleFile]
        }
        do {
            let filesData = try JSONDecoder().decode(FileSearch.self, from: data)
            for f in filesData.files {
                print(f.name, f.parents, filesData.kind)
            }
            for f in filesData.files {
                if f.name == name {
                    return f.id
                }
            }
            self.logger.reportError(self, "File name \(name) not found in folder")
//            for f in filesData.files.sorted{ $0.name < $1.name } {
//                print("  ", f.name)
//            }

        }
        catch {
            self.logger.log(self, "failed load")
        }
        return nil
    }

    func getDataByID(request:DataRequest, onDone: @escaping (_ status:RequestStatus, _ data:Data?) -> Void) {
        getAccessToken()
    }
    
    ///Get a Google Drive resource (file, list of files etc) by its id
    ///First get an OAuth token by issuing a signed request for the required scopes (read). The request is packaged a JWT and signed by the private key of the service account.
    ///Then use that OAuth token to authenticate the call to the Google API

    func getDataByID1(request:DataRequest, onDone: @escaping (_ status:RequestStatus, _ data:Data?) -> Void) {
        struct GoogleClaims: Claims {
            let iss: String
            let scope: String
            let aud: String
            let exp: Date
            let iat: Date
        }
        
        guard let projectEmail = self.getAPIBundleData(key: "projectEmail") else {
            self.logger.reportError(self, "No project email")
            return
        }

        let myHeader = Header(typ: "JWT")
        let myClaims = GoogleClaims(iss: projectEmail,
                                    scope: "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/documents",
                                    aud: "https://oauth2.googleapis.com/token",
                                    exp: Date(timeIntervalSinceNow: 3600),
                                    iat: Date())
        var jwt = JWT(header: myHeader, claims: myClaims)
        struct PrivateKey: Codable {
            let private_key: String
        }

        var privateKey:String?
        let bundleName = "Google_OAuth2_Keys"
        if let url = Bundle.main.url(forResource: bundleName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let decode = try decoder.decode(PrivateKey.self, from: data)
                privateKey = decode.private_key
            } catch {
                self.logger.reportError(self, "Cannot find OAuth key")
                //print("Error: \(error)")
                return
            }
        }
        guard let privateKey = privateKey  else {
            self.logger.reportError(self, "No private key")
            return
        }
        guard let privateKeyData = privateKey.data(using: .utf8) else {
            self.logger.reportError(self, "No private key data")
            return
        }
        var signedJWT = ""
        do {
            signedJWT = try jwt.sign(using: .rs256(privateKey: privateKeyData))
        } catch  {
            self.logger.reportError(self, "Cannot sign JWT \(error)")
            return
        }
        
        ///Request an OAUth2 token using the JWT signature
        ///Exchange the JWT token for a Google OAuth2 access token:
        ///The OAuth2 token is equired to access the API in the next step
            
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        
        let params: Parameters = [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": signedJWT,
        ]
        
        let auth_url = "https://oauth2.googleapis.com/token"
     
        AF.request(auth_url,
                   method: .post,
                   parameters: params,
                   encoding: URLEncoding.httpBody,
                   headers: headers).responseJSON
        {response in
            
            switch response.result {
            case .success(let value):
                let json = value as? [String: Any]
                if let json = json {
                    let accessToken = json["access_token"] as? String
                    if let accessToken = accessToken {
                        //fetchGoogleResourceContent(callType: request.callType, resourceId:request.id, with: accessToken, onDone: onDone)
                        request.accessToken = accessToken
                        fetchGoogleResourceContent(request: request, onDone: onDone)
                    }
                    else {
                        self.logger.reportError(self, "Cannot find access token: \(json)")
                    }
                }
                else {
                    self.logger.reportError(self, "Cannot load JSON")
                }
            case .failure(let error):
                self.logger.reportError(self, "Error getting access token: \(error)")
            }
        }

    //================================== Google Docs document using the Google Docs API and the OAuth2 access token:

    func fetchGoogleResourceContent(request: DataRequest,
                                            onDone: @escaping (_ requestStatus:RequestStatus, Data?) -> Void) {
            guard let accessToken = request.accessToken else {
                self.logger.reportError(self, "No access token")
                return
            }
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)",
                                        "Accept": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
            
            let url:String?

            switch request.callType {
            case .file:
                url = "https://www.googleapis.com/drive/v3/files/\(request.id)?alt=media"
            case .filesInFolder:
                url = "https://www.googleapis.com/drive/v3/files?q='\(request.id)'+in+parents"
            case .googleDoc:
                url = "https://docs.googleapis.com/v1/documents/\(request.id)"
            }
            guard let url = url else {
                self.logger.reportError(self, "No URL for request")
                return
            }
            AF.request(url, headers: headers).response { response in
                switch response.result {
                case .success(let data):
                    if let data = data {
                        //let str = String(data: data, encoding: .utf8)
                        //print("Document content: \(str ?? "No content")")
                        onDone(.success, data)
                    }
                    else {
                        self.logger.reportError(self, "File by ID has no data")
                    }
                case .failure(let error):
                    self.logger.reportError(self, "Error getting drive file by ID \(error.localizedDescription)")
                }
            }
        }
    }
    
}
