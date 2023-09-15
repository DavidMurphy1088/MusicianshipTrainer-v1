import Foundation
import AVFoundation
import SwiftSoup

class TTS {
    static let shared = TTS()
    let google = GoogleAPI.shared
    var audioPlayer: AVAudioPlayer?
    var isSpeaking = false
    let logger = Logger.logger
    let dataCache = DataCache()
    
    func stop() {
        audioPlayer?.stop()
        isSpeaking = false
    }
    
    func play(data:Data) {
        do {
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer?.play()
        } catch {
            logger.reportError(self, "Audio player can't play data")
        }
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
            audioPlayer?.stop()
            return
        }
        isSpeaking = true
        let cacheKey = contentSection.getPath() + "/" + context
        let (cachedType, cachedData) = dataCache.getData(key: cacheKey)
        var playAudio = true
        if let data = cachedData {
            play(data: data)
            if cachedType == .fromMemory {
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
                print(try tag.outerHtml())
                try ssmlContent += filterForSSML(tag.text()) + "<break time=\"1000ms\"/>"
//                cnt += 1
//                if cnt > 2 {
//                    break
//                }
            }
            print(ssmlContent)
        } catch Exception.Error(let type, let message) {
            print("Type: \(type), Message: \(message)")
        } catch {
            print("error")
        }
        ssmlContent += "</speak>"
        //print(ssmlContent)
        

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
