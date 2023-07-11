import Foundation
import SwiftJWT
import Alamofire

struct JSONSheet: Codable {
    let range: String
    let values:[[String]]
}

class GoogleAPI {
    let logger = Logger()
    
    enum DataStatus {
        case ready
        case waiting
        case failed
    }

    func getGoogleAPIData(key:String) -> String? {
        var data:String? = nil
        let pListName = "GoogleAPI"
        if let path = Bundle.main.path(forResource: pListName, ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            data = dict[key] as? String
        }
        guard let data = data else {
            logger.reportError(self, "Cannot find key \(key) in \(pListName).plist")
            return nil
        }
        return data
    }
    
    func getExampleSheet(onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
        let examplesSheetKey:String? = getGoogleAPIData(key: "exampleSheetID")
        if let examplesSheetKey = examplesSheetKey {
            getSheetId(sheetId: examplesSheetKey, onDone: onDone)
        }
        else {
            logger.reportError(self, "Cannot find example sheet id")
            onDone(DataStatus.failed, nil)
        }
    }

    func getSheetId(sheetId:String, onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
        var apiKey:String? = getGoogleAPIData(key: "APIKey")
        guard let apiKey = apiKey else {
            logger.reportError(self, "Cannot find API key")
            onDone(DataStatus.failed, nil)
            return
        }

        var url:String
        url = "https://sheets.googleapis.com/v4/spreadsheets/"
        url +=  sheetId
        url += "/values/Sheet1"
        url += "?key=\(apiKey)"

        guard let url = URL(string: url) else {
            logger.reportError(self, "Sheets, Invalid url \(url)")
            onDone(DataStatus.failed, nil)
            return
        }
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                self.logger.reportError(self, "DataTask Error \(error.localizedDescription)")
                onDone(DataStatus.failed, nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 200 {
                        guard let jsonData = responseString!.data(using: .utf8) else {
                            self.logger.reportError(self, "Invalid JSON data")
                            onDone(DataStatus.failed, nil)
                            return
                        }
                        do {
                            let sheet = try JSONDecoder().decode(JSONSheet.self, from: jsonData)
                            onDone(DataStatus.ready, sheet.values)
                            
                        } catch {
                            self.logger.reportError(self, "JSON Decode Error \(error.localizedDescription)")
                            onDone(DataStatus.failed, nil)
                        }
                    }
                    else {
                        self.logger.reportError(self, "HTTP response code not 200 \(httpResponse.statusCode) \(responseString)")
                        onDone(DataStatus.failed, nil)
                    }
                }
                else {
                    self.logger.reportError(self, "HTTP response, no data")
                    onDone(DataStatus.failed, nil)
                }
            }
        }
        task.resume()
    }
    
    func createJWTToken() {
        struct GoogleClaims: Claims {
            let iss: String
            let scope: String
            let aud: String
            let exp: Date
            let iat: Date
        }
        
        guard let projectEmail = self.getGoogleAPIData(key: "projectEmail") else {
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
        if let url = Bundle.main.url(forResource: "Google_OAuth_Keys", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let decode = try decoder.decode(PrivateKey.self, from: data)
                privateKey = decode.private_key
            } catch {
                print("Error: \(error)")
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
        
        //==================== Exchange the JWT token for a Google OAuth2 access token: ===================
            
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
                        fetchGoogleDocContent(with: accessToken)
                    }
                    else {
                        self.logger.reportError(self, "Cannot find access token")
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

        func fetchGoogleDocContent(with accessToken: String) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)",
                                        "Accept": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
            let fileId = "1U6KbcXardwnRzW7nuLbD2XCWXTqo5Vad"
            let fileURL = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media"

            AF.request(fileURL, headers: headers).response { response in
                switch response.result {
                case .success(let data):
                    if let data = data {
                        let str = String(data: data, encoding: .utf8)
                        print("Document content: \(str ?? "No content")")
                    }
                    else {
                        self.logger.reportError(self, "File by ID has no data")
                    }
                case .failure(let error):
                    self.logger.reportError(self, "Error getting drive file by ID")
                }
            }
        }
    }
    
    
    //    func authenticateWithServiceAccount() {
    //        var jsonData1:Data
    //        if let filePath = Bundle.main.path(forResource: "googl-service-account-keys", ofType: "json") {
    //            let fileURL = URL(fileURLWithPath: filePath)
    //            do {
    //                jsonData1 = try Data(contentsOf: fileURL)
    //                //return data
    //            } catch {
    //                print("Error loading data from file: \(error.localizedDescription)")
    //            }
    //        }
    //
    //
    //        let service = GTLRDriveService()
    //
    //        // Configure the service account authentication
    //        service.authorizer = try? GTMAppAuthFetcherAuthorization(fromKeychainForName: "YOUR_KEYCHAIN_NAME")
    //
    //        // Make API requests using the Google Drive service
    //
    //        let query = GTLRDriveQuery_FilesList.query()
    //        query.pageSize = 10
    //
    //        service.executeQuery(query) { (ticket, files, error) in
    //            if let error = error {
    //                print("Error listing files: \(error.localizedDescription)")
    //                return
    //            }
    //
    //            if let files = files as? GTLRDrive_FileList, let items = files.files {
    //                for item in items {
    //                    print(item.name ?? "Unknown")
    //                }
    //            }
    //        }
    //    }
    
    //    func getDriveFileId(id:String, onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
    //        //This will give you metadata about the file. To get the actual file content, you would typically use the alt=media query parameter, but it doesn't
    //        //work with API Keys. It requires OAuth 2.0 authentication, as the file content is considered sensitive data even if the file is public.
    //        //Remember, using an API key has security implications and limitations. It only provides access to publicly accessible data and doesn't allow for modification
    //        //of files or access to more sensitive data.
    //        //For full functionality, OAuth 2.0 is the recommended method to access files on Google Drive programmatically.
    //
    //        var url = "https://drive.google.com/file/d/\(id)/view"
    //        url += "?key=AIzaSyAE2BUYT57itqrYlVR4wIg8yszz9J88nQ8" //API key
    //        guard let url = URL(string: url) else {
    //            print("Invalid URL")
    //            logger.reportError(self, "Invalid url \(url)")
    //            onDone(DataStatus.failed, nil)
    //            return
    //        }
    //        let session = URLSession.shared
    //
    //        let task = session.dataTask(with: url) { (data, response, error) in
    //            if let error = error {
    //                //print("Error: \(error.localizedDescription)")
    //                self.logger.reportError(self, "dataTask Error \(error.localizedDescription)")
    //                onDone(DataStatus.failed, nil)
    //            } else if let httpResponse = response as? HTTPURLResponse {
    //                print("Status code: \(httpResponse.statusCode)")
    //
    //                if let data = data {
    //                    // Process the response data
    //                    let responseString = String(data: data, encoding: .utf8)
    //                    //print("Response: \(responseString ?? "")")
    //                    if httpResponse.statusCode == 200 {
    //                        guard let jsonData = responseString!.data(using: .utf8) else {
    //                            self.logger.reportError(self, "Invalid JSON data")
    //                            onDone(DataStatus.failed, nil)
    //                            return
    //                        }
    //                        do {
    //                            let sheet = try JSONDecoder().decode(JSONSheet.self, from: jsonData)
    //                            onDone(DataStatus.ready, sheet.values)
    //
    //                        } catch {
    //                            self.logger.reportError(self, "JSON Decode Error \(error.localizedDescription)")
    //                            onDone(DataStatus.failed, nil)
    //                        }
    //                    }
    //                    else {
    //                        self.logger.reportError(self, "HTTP response code \(httpResponse.statusCode) \(responseString)")
    //                        onDone(DataStatus.failed, nil)
    //                    }
    //                }
    //            }
    //            //}
    //        }
    //        task.resume()
    //    }
    
    //func getToken1() {
//        // ================= Get a JWT token for your service account: ===================
//
//        let header = Header(kid: "...")
//
//        let claims = ClaimsStandardJWT(
//            iss: "...",
//            aud: ["https://www.googleapis.com/oauth2/v4/token"],
//            exp: Date().addingTimeInterval(3600),
//            iat: Date()
//        )
//
//        var jwt = JWT(header: header, claims: claims)
//
//        let privateKey = """
//        -----BEGIN PRIVATE KEY-----...
//        -----END PRIVATE KEY-----
//        """
//        guard let privateKeyData = privateKey.data(using: .utf8) else {
//            print("Failed to convert string to data")
//            return
//        }
//        var signedJWT = ""
//        do {
//            signedJWT = try jwt.sign(using: .rs256(privateKey: privateKeyData))
//        } catch  {
//            print("Failed to sign JWT: \(error)")
//        }
//        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
//
//        let params: Parameters = [
//            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
//            "assertion": signedJWT,
//            "scope": "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/documents.readonly"
//        ]
//
//        AF.request("https://oauth2.googleapis.com/token",
//                   method: .post,
//                   parameters: params,
//                   encoding: URLEncoding.httpBody,
//                   headers: headers).responseJSON { response in
//            switch response.result {
//            case .success(let value):
//                let json = value as? [String: Any]
//                if let json = json {
//                    let accessToken = json["access_token"] as? String
//                    if let accessToken = accessToken {
//                        //fetchGoogleDocContent(with: accessToken)
//                    }
//                }
//            case .failure(let error):
//                print("Error getting access token: \(error)")
//            }
//        }
//    }
//
    //    func getDocument(onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
    //        var url = "https://docs.googleapis.com/v1/documents/"
    //        url += "1ywIemFFkPwh-jzIReU9qAu511qKeOrJBa-bTjHQ6rTM" //document id
    //        url += "?key=AIzaSyAE2BUYT57itqrYlVR4wIg8yszz9J88nQ8" //API key
    //        guard let url = URL(string: url) else {
    //            print("Invalid URL")
    //            logger.reportError(self, "Invalid url \(url)")
    //            onDone(DataStatus.failed, nil)
    //            return
    //        }
    //        let session = URLSession.shared
    //
    //        let task = session.dataTask(with: url) { (data, response, error) in
    //            if let error = error {
    //                print("Error: \(error.localizedDescription)")
    //                self.logger.reportError(self, "dataTask Error \(error.localizedDescription)")
    //                onDone(DataStatus.failed, nil)
    //            } else if let httpResponse = response as? HTTPURLResponse {
    //                print("Status code: \(httpResponse.statusCode)")
    //                if let data = data {
    //                    // Process the response data
    //                    let responseString = String(data: data, encoding: .utf8)
    //                    print("Response: \(responseString ?? "")")
    //                    guard let jsonData = responseString!.data(using: .utf8) else {
    //                        self.logger.reportError(self, "Invalid JSON data")
    //                        onDone(DataStatus.failed, nil)
    //                        return
    //                    }
    //                    do {
    //                        let sheet = try JSONDecoder().decode(JSONSheet.self, from: jsonData)
    //                        onDone(DataStatus.ready, sheet.values)
    //
    //                    } catch {
    //                        self.logger.reportError(self, "JSON Decode Error \(error.localizedDescription)")
    //                        onDone(DataStatus.failed, nil)
    //                    }
    //                }
    //            }
    //        }
    //        task.resume()
    //    }
}
