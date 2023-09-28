import Foundation
import AVKit
import AVFoundation

class AudioSamplerPlayer {
    static private var shared = AudioSamplerPlayer()
    private var audioEngine = AVAudioEngine()
    private var sampler = AVAudioUnitSampler()
    private var stopPlayingNotes = false
    
    private init() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)

        do {
            try audioEngine.start()
        } catch {
            Logger.logger.reportError(self, "Could not start the audio engine: \(error)")
        }
        loadSoundFont()
    }
    
    static public func getShared() -> AudioSamplerPlayer {
        return AudioSamplerPlayer.shared
    }
    
    static public func reset() {        
        AudioSamplerPlayer.shared = AudioSamplerPlayer()
    }
    
    public func stopPlaying() {
        stopPlayingNotes = true
    }
    
    public func getSampler() -> AVAudioUnitSampler {
        return sampler
    }
    

    
    private func loadSoundFont() {
        
        //https://www.rockhoppertech.com/blog/the-great-avaudiounitsampler-workout/#soundfont
        //https://sites.google.com/site/soundfonts4u/
        let soundFontNames = [("Piano", "Nice-Steinway-v3.8"), ("Guitar", "GuitarAcoustic")]
        //let soundFontNames = [("Piano", "marcato strings"), ("Guitar", "GuitarAcoustic")]
        //var soundFontNames = [("Piano", "Dore Mark's (SF) Fazioli-v2.5.sf2"), ("Guitar", "GuitarAcoustic")]
        let samplerFileName = soundFontNames[0].1
        
        AppDelegate.startAVAudioSession(category: .playback)
//        midiSampler = AVAudioUnitSampler()
//        audioEngine.attach(midiSampler)
//        audioEngine.connect(midiSampler, to:audioEngine.mainMixerNode, format:audioEngine.mainMixerNode.outputFormat(forBus: 0))
        //18May23 -For some unknown reason and after hours of investiagtion this loadSoundbank must oocur before every play, not jut at init time
        
        if let url = Bundle.main.url(forResource:samplerFileName, withExtension:"sf2") {
            let ins = 0
            for instrumentProgramNumber in ins..<256 {
                do {
                    try sampler.loadSoundBankInstrument(at: url, program: UInt8(instrumentProgramNumber), bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: UInt8(kAUSampler_DefaultBankLSB))

                    //print("SF2", instrumentProgramNumber)
                    //Metronome.nextInstrument += 1
                    break
                }
                catch {
                }
                
            }
        }
        else {
            Logger.logger.reportError(self, "Cannot loadSoundBankInstrument \(samplerFileName)")
        }
        
//        do {
//            try audioEngine.start()
//        }
//        catch let error {
//            Logger.logger.reportError(self, "Cant create MIDI sampler \(error.localizedDescription)")
//        }
    }

    func play(note: UInt8) {
        sampler.startNote(note, withVelocity: 127, onChannel: 0)
    }

    func stop(note: UInt8) {
        sampler.stopNote(note, onChannel: 0)
    }
    
    func playNotes(notes: [Note]) {
        stopPlayingNotes = false
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let playTempo = 16.0
            let pitchAdjust = 0
            var n = 0
            for note in notes {
                if stopPlayingNotes {
                    break
                }
                let dynamic:Double = 48
                n += 1
                sampler.startNote(UInt8(note.midiNumber + pitchAdjust), withVelocity:UInt8(dynamic), onChannel:0)
                let wait = playTempo * 50000.0 * Double(note.getValue())
                usleep(useconds_t(wait))
            }
        }
    }

}

