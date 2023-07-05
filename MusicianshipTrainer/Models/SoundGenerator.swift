import Foundation
import AVKit
import AVFoundation

//class SoundGenerator {
//    static public var soundGenerator:SoundGenerator = SoundGenerator()
//    static private let engine = AVAudioEngine()
//    static let sampler = AVAudioUnitSampler()
//    
//    init()  {
//        SoundGenerator.engine.attach(SoundGenerator.sampler)
//        SoundGenerator.engine.connect(SoundGenerator.sampler, to:SoundGenerator.engine.mainMixerNode, format:SoundGenerator.engine.mainMixerNode.outputFormat(forBus: 0))
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                //https://www.rockhoppertech.com/blog/the-great-avaudiounitsampler-workout/#soundfont
//                if let url = Bundle.main.url(forResource:"Nice-Steinway-v3.8", withExtension:"sf2") {
//                    do {
//                        try SoundGenerator.sampler.loadSoundBankInstrument(at: url, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: UInt8(kAUSampler_DefaultBankLSB))
//                    }
//                    catch let error as NSError {
//                        Logger.logger.reportError(self, "Failed to load sound bank instrument", error)
//                    }
//                }
//                try SoundGenerator.engine.start()
//            } catch let error as NSError {
//                Logger.logger.reportError(self, "Couldn't start engine", error)
//            }
//        }
//    }
//    
//    func playNote(notePitch:Int) {
//        SoundGenerator.sampler.startNote(UInt8(notePitch), withVelocity:48, onChannel:0)
//    }
//}
