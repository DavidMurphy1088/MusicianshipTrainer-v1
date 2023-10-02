import Foundation
import AVFoundation
import SwiftSoup

class TTS : AudioPlayerUser {
    static let shared = TTS(parent: "TTS")
    let google = GoogleAPI.shared
    var isSpeaking = false
    let dataCache = DataCache()
    
    override func stop() {
        super.stop()
        isSpeaking = false
    }
    
    func filterForSSML(_ input: String) -> String {
        return input.filter { char in
            //let validLowercase = Character("a") ... Character("z")
            //let validUppercase = Character("A") ... Character("Z")
            //return validLowercase.contains(char) || validUppercase.contains(char) || char == "."
            return char != "&"
        }
    }

    func speakText(contentSection:ContentSection, context:String, htmlContent:String) {
        if isSpeaking {
            isSpeaking = false
            stop()
            return
        }
        isSpeaking = true
        let cacheKey = contentSection.getPath() + "/" + context
        let (cachedType, data) = dataCache.getData(key: cacheKey)
        var playAudio = true
        if let data = data {
            play(data: data)
            if cachedType == .fromMemoryCache {
                return
            }
            playAudio = false
        }

        let apiKey:String? = google.getAPIBundleData(key: "APIKey")
        let apiUrl = "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey ?? "")"
        //voices https://cloud.google.com/text-to-speech/docs/voices
        
        var ssmlContent = "<speak>"
        do {
            let doc: Document = try SwiftSoup.parse(htmlContent)
            let tags: Elements = try doc.select("p, h1")
            var cnt = 0
            for tag in tags {
                try ssmlContent += filterForSSML(tag.text()) + "<break time=\"1000ms\"/>"
            }
        } catch Exception.Error(let type, let message) {
            Logger.logger.reportError(self, "Type: \(type), Message: \(message)")
        } catch {
            Logger.logger.reportError(self,"Error")
        }
        ssmlContent += "</speak>"

        let requestBody: [String: Any] = [
            "input": ["ssml": ssmlContent],
            "voice": ["languageCode": "en-US",
                      "name": "en-AU-Wavenet-A"],
            "audioConfig": ["audioEncoding": "MP3"]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: requestBody, options: [])
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let data = data, error == nil else {
                logger.reportError(self, error?.localizedDescription ?? "Unknown")
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let audioContent = jsonResponse["audioContent"] as? String,
                    let audioData = Data(base64Encoded: audioContent) {
                    self.dataCache.setData(key: cacheKey, data: audioData)
                    if playAudio {
                        self.play(data: audioData)
                    }
                }
                else {
                    logger.reportError(self, error?.localizedDescription ?? "Unknown")
                }
            } catch {
                logger.reportError(self, error.localizedDescription)
            }
        }
        task.resume()
    }
}
