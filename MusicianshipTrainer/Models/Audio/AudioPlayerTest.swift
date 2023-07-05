import AVFoundation
import AudioKit
import Foundation

class AudioPlayerTest {
    var engine:AudioKit.AudioEngine
    var player:AudioPlayer?
    //let mic: AudioEngine.InputNode
    
    init() {
        engine = AudioKit.AudioEngine()
    }
    
    func test() {
        let url = Bundle.main.url(forResource: "Example 1", withExtension: "wav")
        player = AudioPlayer(url: url!)
        engine.output = player
        //let bufferSize: UInt32 = 8192
        //let fftValidBinCount: FFTValidBinCount? = .full
        let callbackQueue = DispatchQueue.main

//        let fftTap = FFTTap(player!, callbackQueue: callbackQueue) {x in
//            print("fftTap", x)
//        }
        
        //----------------------------
        //TunerConductor
        guard let input = engine.input else { fatalError() }

        guard let device = engine.inputDevice else { fatalError() }

        //initialDevice = device

//        mic = input
//        tappableNodeA = Fader(mic)
//        tappableNodeB = Fader(tappableNodeA)
//        tappableNodeC = Fader(tappableNodeB)
//        silence = Fader(tappableNodeC, gain: 0)
//        engine.output = silence
//
//        tracker = PitchTap(mic) { pitch, amp in
//            DispatchQueue.main.async {
//                self.update(pitch[0], amp[0])
//            }
//        }
//        tracker.start()

        //----------------------------
        
        //what is PitchTap ?????????? https://www.audiokit.io/SoundpipeAudioKit/documentation/soundpipeaudiokit/pitchtap
        
        //let ampTap = AmplitudeTap(engine.input!, callbackQueue: DispatchQueue.main) {a in
        let ampTap = AmplitudeTap(player!, callbackQueue: DispatchQueue.main) {a in
            //print("AmpTap", a)
        }
    //    ampTap.analysisMode = .peak
    //
        do {
            try engine.start()
            try player!.start()
            //fftTap.start()     // installs this tap on the player bus
            ampTap.start()
            //ampTracker.start() // removes the fftTap and installs this one
         }
         catch
         {
            print("Could not start engine: %\(error)")
            return
        }
            
    }
}

