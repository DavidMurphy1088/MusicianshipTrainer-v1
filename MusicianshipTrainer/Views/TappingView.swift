import SwiftUI
import CoreData

enum TapState {
    case inactive
    case active(location: CGPoint)
}
class Invert : ObservableObject {
    @Published var invert = true
    func rev() {
        DispatchQueue.main.async {
            self.invert.toggle()
        }
    }
}

struct TappingView: View {
    @Binding var isRecording:Bool
    @ObservedObject var tapRecorder:TapRecorder
    var onDone: ()->Void

    @State var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "TappingView")
    @State private var tapRecords: [CGPoint] = []
    @State var ctr = 0
    @ObservedObject var invert:Invert = Invert()
    @State private var isScaled = false
    @State var tapSoundOn = false
    
    var body: some View {
        VStack {
            ZStack {
                Image("drum_transparent")
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: UIScreen.main.bounds.width / 4.0)
                .padding()
                .clipShape(Circle())
                .padding()
                .overlay(Circle().stroke(invert.invert ? Color.white : Color.black, lineWidth: 4))
                .shadow(radius: 10)
            
                if isRecording {
                    if tapRecorder.enableRecordingLight {
                        Image(systemName: "stop.circle")
                            .foregroundColor(Color.red)
                            .font(.system(size: isScaled ? 70 : 50))
                            .onAppear {
                                self.isScaled.toggle()
                            }
                    }
                }
            }
            .padding()
            .onTapGesture {
                if isRecording {
                    invert.rev()
//                    if !tapSoundOn {
                        tapRecorder.makeTap(useSoundPlayer: false)
//                    }
//                    else {
//                        tapRecorder.makeTap(useSoundPlayer: false)
//                    }
                }
            }
//            .gesture(
//                DragGesture(minimumDistance: 0)
//                    .onChanged({ _ in
//                        invert.rev()
//                        if tapSoundOn {
//                            if isRecording {
//                                tapRecorder.makeTap(useSoundPlayer: self.tapSoundOn)
//                            }
//                        }
//                    })
//            )

//            Text("").padding()
//            Button(action: {
//                self.tapSoundOn.toggle()
//                UIGlobals.rhythmTapSoundOn = self.tapSoundOn
//            }) {
//                Image(systemName: self.tapSoundOn ? "checkmark.square" : "square")
//                Text(self.tapSoundOn ? "Tap Sound Off" : "Tap Sound On")
//            }
            Text("").padding()
            Button(action: {
                onDone()
            }) {
                Text("Stop Recording").defaultButtonStyle()
            }
        }
        .onAppear() {
            self.tapSoundOn = UIGlobals.rhythmTapSoundOn
        }
    }
    
}





