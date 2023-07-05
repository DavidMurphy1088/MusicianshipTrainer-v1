import SwiftUI
import CoreData
import AVFoundation

// Record and then play audio of a student playing

class AudioRecorder : NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate, ObservableObject {
    static let shared = AudioRecorder()
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioFilename:URL?
    @Published var status:String = ""
    
    func setStatus(_ msg:String) {
        //print("AudioRecorder::status", msg)
        DispatchQueue.main.async {
            self.status = "AudioRecorder::"+msg
        }
    }
    
    func startRecording(outputFileName:String)  {
        recordingSession = AVAudioSession.sharedInstance()
        audioFilename = getDocumentsDirectory().appendingPathComponent("\(outputFileName).wav")
        //print("RECORDING TO file:", audioFilename ?? "")

        AppDelegate.startAVAudioSession(category: .record)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            if audioRecorder == nil {
                Logger.logger.reportError(self, "Recording, audio record is nil")
            }
            audioRecorder.delegate = self
            audioRecorder.record()
            
//            var resourceValues = URLResourceValues()
//            resourceValues.isExcludedFromBackup = false
//            resourceValues.isHidden = false
//            resourceValues.mayShareFileContent = true
//            resourceValues[.isExtensionHidden] = false
//            resourceValues[.posixPermissions] = 0o644 // Adjust the permissions as needed
//            try destinationURL.setResourceValues(resourceValues)

            if audioRecorder.isRecording {
                setStatus("Recording started, status:\(audioRecorder.isRecording ? "OK" : "Error")")
            }
            else {
                Logger.logger.reportError(self, "Recording, recorder is not recording")
            }
        } catch let error {
            Logger.logger.reportError(self, "Recording did not start", error)
            stopRecording()
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        setStatus("Recording stopped, status:\(flag ? "OK" : "Error")")
    }

    func stopRecording() {
        Logger.logger.log(self, "Trying to stop recorder")
        if audioRecorder == nil {
            Logger.logger.reportError(self, "audioRecorder is nil at stop")
        }
        else {
            Logger.logger.log(self, "Recording ended - wasRecording? -\(audioRecorder.isRecording) secs:\(String(format: "%.1f", audioRecorder.currentTime))")
            setStatus("Recorded time \(String(format: "%.1f", audioRecorder.currentTime)) seconds")
            audioRecorder.stop()
            AppDelegate.startAVAudioSession(category: .playback)
        }
    }

    func playRecording() {
        //Logger.logger.log(self, "Playback starting")
        AppDelegate.startAVAudioSession(category: .playback)
        guard let url = audioFilename else {
            Logger.logger.reportError(self, "At playback, file URL is nil")
            return
        }
        let fileManager = FileManager.default
        //print("PLAYING FROM:", audioFilename)
        if !fileManager.fileExists(atPath: url.path) {
            Logger.logger.reportError(self, "At playback, file does not exist \(url.path)")
            return
        }
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: audioFilename!)
            if self.audioPlayer == nil {
                Logger.logger.reportError(self, "At playback, cannot create audio player for \(url.path)")
                return
            }
            //var msg = "playback started, still recording? \(audioRecorder.isRecording)"
            //setStatus(msg)
            //Logger.logger.log(self, msg)
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
            setStatus("Playback started, status:\(self.audioPlayer.isPlaying ? "OK" : "Error")")
        } catch let error {
            Logger.logger.reportError(self, "At Playback, start playing error", error)
        }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setStatus("Playback stopped, status:\(flag ? "OK" : "Error")")
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //let paths = FileManager.default.urls(for: .sharedPublicDirectory, in: .userDomainMask)
        
//        for p in paths {
//            print("getDocumentsDirectory", p)
//        }
        return paths[0]
    }
}

