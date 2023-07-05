import SwiftUI
import CoreData
import AVFoundation

struct ClapTestView: View {
    let synthesizer = AVSpeechSynthesizer()
    //https://dolby.io/blog/recording-audio-on-ios-with-examples/
    @State private var requiredDecibelChange:Double = Double(ClapRecorder.requiredDecibelChangeInitial)
    @State private var requiredBufferSize = Double(ClapRecorder.requiredBufSizeInitial)

    @State private var tempo = Double(1000)
    
    @State private var isRecording = false
    @ObservedObject var clapRecorder:ClapRecorder = ClapRecorder()
    @ObservedObject var metronome:Metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "ClapTestView")

    private class CompletionHandler: NSObject, AVSpeechSynthesizerDelegate {
        let completion: (() -> Void)?
        
        init(_ completion: (() -> Void)? = nil) {
            self.completion = completion
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            completion?()
        }
    }

    func speak(_ sentence: String, completion: (() -> Void)? = nil) {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let voice = "en-US" //en-US"

        for v in voices {
            //print(v, v.language)
            if v.description == voice.description {
                print(v)
                break
            }
        }
        let utterance = AVSpeechUtterance(string: sentence)
        guard let voice = AVSpeechSynthesisVoice(language: voice) else {
            print("Error: Language not supported", voice)
            return
        }
        utterance.voice = voice
        synthesizer.speak(utterance)
        synthesizer.delegate = CompletionHandler(completion)
    }

    var body: some View {
        VStack {
            Button("Speak") {
                speak("Hello world")
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    //metronome.startTicking()
                }) {
                    Text("Start Metronome")
                }
                Spacer()
                Button(action: {
                    //metronome.tickIsOn = false
                }) {
                    Text("Stop Metronome")
                }
                Spacer()
            }
            Spacer()
            if isRecording {
                VStack {
                    Text("Claps recorded \(self.clapRecorder.clapCounter)").padding()
                    Button(action: {
                        clapRecorder.stopRecording()
                        self.isRecording = false
                    }) {
                        Text("Stop Listening").padding()
                    }
                }
            }
            else {
                Button(action: {
                    #if targetEnvironment(simulator)
                    print("Running on simulator")
                    #else
                    clapRecorder.startRecording()
                    #endif
                    self.isRecording = true
                }) {
                    Text("Listen to Clapping")
                }
            }

            Spacer()
            VStack {
                Text("Tempo: \(Int(tempo))")
//                HStack {
//                    Slider(value: $tempo, in: 0...2000, onEditingChanged: { value in
//                        //print("Slider value changed to: \(requiredDecibelChange)")
//                        metronome.setTempo(tempo: tempo)
//                    })
//                }.padding()

                Text("Required Decibel Change: \(Int(requiredDecibelChange))")
                HStack {
                    Slider(value: $requiredDecibelChange, in: 0...50, onEditingChanged: { value in
                        //print("Slider value changed to: \(requiredDecibelChange)")
                        clapRecorder.setRequiredDecibelChange(change: Int(requiredDecibelChange))
                    })
                }.padding()
                Text("Required Buffer Size: \(Int(requiredBufferSize))")
                HStack {
                    Slider(value: $requiredBufferSize, in: 0...128, onEditingChanged: { value in
                        //print("Slider value changed to: \(requiredDecibelChange)")
                        clapRecorder.setRequiredBufferSize(change: Int(requiredBufferSize))
                    })
                }.padding()
            }

        }
    }
}

