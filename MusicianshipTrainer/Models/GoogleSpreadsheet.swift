import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher

struct JSONSheet: Codable {
    let range: String
    let values:[[String]]
}

class GoogleSpreadsheet {
    let logger = Logger()
    
    enum DataStatus {
        case ready
        case waiting
        case failed
    }
    
    func test() {
        let serviceAccountKeyPath = "path/to/service_account_key.json"

        func connectToDriveAPI() {
            // Load the service account JSON key file
            guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: serviceAccountKeyPath)),
                  let credentials = try? GoogleCredentials.from(jsonKeyData: jsonData) else {
                print("Failed to load service account credentials.")
                return
            }

            // Create a GTMSessionFetcherService and set the credentials
            let fetcherService = GTMSessionFetcherService()
            fetcherService.authorizer = try? credentials.authorize()

            // Create a Google Drive service and set the fetcher service
            let driveService = GTLRDriveService()
            driveService.fetcherService = fetcherService

            // Make API requests using the Google Drive service
            listFiles(using: driveService)
        }

        func listFiles(using service: GTLRDriveService) {
            let query = GTLRDriveQuery_FilesList.query()
            query.pageSize = 10

            service.executeQuery(query) { (ticket, files, error) in
                if let error = error {
                    print("Error listing files: \(error.localizedDescription)")
                    return
                }

                if let files = files as? GTLRDrive_FileList, let items = files.files {
                    for item in items {
                        print(item.name ?? "Unknown")
                    }
                }
            }
        }

        // Call the connectToDriveAPI function to initiate the connection
        connectToDriveAPI()

    }
    func getFile(onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
        //---> API keys are not supported by this API. Expected OAuth2 access token or other authentication credentials
        //that assert a principal. See https://cloud.google.com/docs/authentication
        //var url = "https://docs.googleapis.com/v1/documents/"
        //var url = "https://www.googleapis.com/drive/v2/files/12VCNR7qtn0PTeKo2wfN2YMcpLL6ASa0k?alt=media&source=downloadUrl"
        var url = "https://docs.google.com/document/d/1ywIemFFkPwh-jzIReU9qAu511qKeOrJBa-bTjHQ6rTM/edit?usp=sharing"
        //url += "1ywIemFFkPwh-jzIReU9qAu511qKeOrJBa-bTjHQ6rTM" //document id
        //url += "?key=AIzaSyAE2BUYT57itqrYlVR4wIg8yszz9J88nQ8" //API key
        
   // Authorization: Bearer ya29.a0AbVbY6PN9OQWsJRxV3WQH1xmSPTOoqQFdSzSNUOt1r6GAzfFCOPnOXUhxMs2lZBb3L0Bd6eEL1pfVs-i28ZW_gENcdmM-
        
        guard let url = URL(string: url) else {
            print("Invalid URL")
            logger.reportError(self, "Invalid url \(url)")
            onDone(DataStatus.failed, nil)
            return
        }
        let session = URLSession.shared
        //session.request.addValue("Bearer your-access-token", forHTTPHeaderField: "Authorization")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
//        var auth = ""
//        auth += "Bearer ya29.a0AbVbY6PN9OQWsJRxV3WQH1xmSPTOoqQFdSzSNUOt1r6GAzfFCOPnOXUhxMs2lZBb3L0Bd6eEL1pfVs"
//        auth += "-i28ZW_gENcdmM-ehjxzjoECIL1lQJCod8ng98AU05wNtlTqa11uHADdA1YE249CkYKF"
//        auth += "BmZzXwjNP7aCgYKAdISARESFQFWKvPlIaHF3VHadIHpa7wLNBT6WQ0163"
//        print (auth)
//        request.addValue(auth, forHTTPHeaderField: "Authorization")

        // Create a URLSession
        let task = session.dataTask(with: request) { (data, response, error) in

        //let task = session.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.logger.reportError(self, "dataTask Error \(error.localizedDescription)")
                onDone(DataStatus.failed, nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                if let data = data {
                    print(String(data: data, encoding: .utf8))
//                    // Process the response data
//                    let responseString = String(data: data, encoding: .utf8)
//                    //print("Response: \(responseString ?? "")")
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
                }
            }
        }
        task.resume()
    }

    func getSheet(onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
        
        // Create a URL object for the HTTP endpoint
        var url = "https://sheets.googleapis.com/v4/spreadsheets/"
        url += "1tjvlANvWh8O48SCSi2zuF1duSCiXVugnRw4MGMrL5ag" //spreadsheet id
        url += "/values/Sheet1"
        url += "?key=AIzaSyAE2BUYT57itqrYlVR4wIg8yszz9J88nQ8" //API key
        guard let url = URL(string: url) else {
            print("Invalid URL")
            logger.reportError(self, "Invalid url \(url)")
            onDone(DataStatus.failed, nil)
            return
        }
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.logger.reportError(self, "dataTask Error \(error.localizedDescription)")
                onDone(DataStatus.failed, nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                if let data = data {
                    // Process the response data
                    let responseString = String(data: data, encoding: .utf8)
                    //print("Response: \(responseString ?? "")")
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
            }
        }
        task.resume()
    }
}
