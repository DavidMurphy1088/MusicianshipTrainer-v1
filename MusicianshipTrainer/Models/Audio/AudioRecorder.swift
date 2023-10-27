import SwiftUI
import CoreData
import AVFoundation

// Record and then play audio of a student playing

class AudioRecorder : NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate, ObservableObject {
    static let shared = AudioRecorder()
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer! //best for playing smaller local content
    let logger = Logger.logger

    ///use the same name for all recordings.
    var audioFilenameStatic = "Audio_Recording"
    var avPlayer: AVPlayer? //best for playing remote content, support streaming etc
    var playEndedNotify:(()->Void)?
    
    @Published var status:String = ""
    
    func setStatus(_ msg:String) {
        DispatchQueue.main.async {
            self.status = "AudioRecorder::"+msg
        }
    }
    
    func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            completion(granted)
        }
    }
    func log(_ msg:String) {
        logger.log(self, msg)
    }
    
    func startRecording(fileName:String)  {
        let outputFileName = audioFilenameStatic
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(outputFileName).wav")
        
        let permissionStatus = checkMicrophonePermission()
        switch permissionStatus {
        case .granted:
            log("Mic - Permission granted")
        case .denied:
            log("Mic - Permission denied")
        case .undetermined:
            log("Mic - Permission undetermined")
            requestMicrophonePermission { granted in
                if granted {
                    self.log("Mic - Permission granted after request")
                } else {
                    self.logger.reportError(self, "Mic - Permission denied after request")
                }
            }
        @unknown default:
            logger.reportError(self, "Mic - Unknown permission status")
        }

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        AudioManager.shared.setSession(.record)
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            if audioRecorder == nil {
                Logger.logger.reportError(self, "Recording, audio record is nil")
            }
            audioRecorder.delegate = self
            audioRecorder.record()

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
        AudioManager.shared.setSession(.playback)
    }

    func stopRecording() {
        Logger.logger.log(self, "Trying to stop recorder")
        if audioRecorder == nil {
            Logger.logger.reportError(self, "audioRecorder is nil at stop")
        }
        else {
            Logger.logger.log(self, "Recording ended - wasRecording? -\(audioRecorder.isRecording) seconds:\(String(format: "%.1f", audioRecorder.currentTime))")
            setStatus("Recorded time \(String(format: "%.1f", audioRecorder.currentTime)) seconds")
            audioRecorder.stop()
        }
        AudioManager.shared.setSession(.playback)
    }
    
    func getRecordedAudio(fileName:String) -> Data? {
        let audioFilename = audioFilenameStatic
        let url = getDocumentsDirectory().appendingPathComponent("\(audioFilename).wav")
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch let error {
            Logger.logger.reportError(self, "Cant read data for file \(String(describing: audioFilename))", error)
            return nil
        }
    }

    func playRecording(fileName:String) {
        //AppDelegate.startAVAudioSession(category: .playback)
        let audioFilename = self.audioFilenameStatic
        let url = getDocumentsDirectory().appendingPathComponent("\(audioFilename).wav")
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            //self.audioPlayer = try AVAudioPlayer(url: audioFilename)
            if self.audioPlayer == nil {
                Logger.logger.reportError(self, "At playback, cannot create audio player for \(url)")
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
    
    func playFromData(data:Data, onDone:@escaping ()->Void) {
        do {
            self.audioPlayer = try AVAudioPlayer(data: data)
            if self.audioPlayer == nil {
                Logger.logger.reportError(self, "playFromData, cannot create audio player")
                return
            }
            //var msg = "playback started, still recording? \(audioRecorder.isRecording)"
            //setStatus(msg)
            //Logger.logger.log(self, msg)
            self.playEndedNotify = onDone
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
            setStatus("Playback started, status:\(self.audioPlayer.isPlaying ? "OK" : "Error")")
        } catch let error {
            Logger.logger.reportError(self, "At Playback, start playing error", error)
        }
    }
    
    func stopPlaying() {
        if self.audioPlayer != nil {
            self.audioPlayer.stop()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setStatus("Playback stopped, status:\(flag ? "OK" : "Error")")
        if let playEndedNotify = self.playEndedNotify {
            playEndedNotify()
        }
//        if let allDone = self.allDoneCallback {
//            let status:RequestStatus = flag ? .success : .failed
//            allDone(status)
//        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func playAudioFromCloudURL(urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.logger.reportError(self, "Invalid URL")
            return
        }

        avPlayer = AVPlayer(url: url)
        if let avPlayer = avPlayer {
            avPlayer.play()
        }
    }
}

