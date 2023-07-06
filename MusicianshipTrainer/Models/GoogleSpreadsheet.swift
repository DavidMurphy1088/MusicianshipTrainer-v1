
import Foundation

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

    func get(onDone: @escaping (_ dataStatus:DataStatus, [[String]]?) -> Void) {
        
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
                //print("Status code: \(httpResponse.statusCode)")
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
