import SwiftUI
import CoreData

enum TapState {
    case inactive
    case active(location: CGPoint)
}

class Invert : ObservableObject {
    @Published var invert = true
    func switchBorder() {
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
    //@State var soundOn = false
    //@State var upStroke = true

    func drumView() -> some View {
        VStack {
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
    }

    var body: some View {
        VStack {
            ///.onTapGesture and .gesture can't interoperate... -> use one or the other
            //if upStroke {
            if Settings.useUpstrokeTaps {
                ZStack {
                    drumView()
                }
                .padding()
                .onTapGesture {
                    ///Fires on up stroke
                    if isRecording {
                        invert.switchBorder()
                        tapRecorder.makeTap(useSoundPlayer:Settings.soundOnTaps)
                    }
                }
            }
            else {
                ZStack {
                    drumView()
                }
                .padding()
                .gesture(
                    ///Fires on downstroke
                    DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        if isRecording {
                            invert.switchBorder()
                            tapRecorder.makeTap(useSoundPlayer:Settings.soundOnTaps)
                        }
                    })
                )
            }

//            Text("").padding()
//            HStack {
//                Button(action: {
//                    soundOn.toggle()
//                }) {
//                    HStack {
//                        Image(systemName: soundOn ? "checkmark.square" : "square")
//                        Text("Sound On?")
//                    }
//                }
//                .padding()
//
//                Button(action: {
//                    upStroke.toggle()
//                }) {
//                    HStack {
//                        Image(systemName: upStroke ? "square" : "checkmark.square")
//                        Text("Use Down Stroke?")
//                    }
//                }
//                .padding()
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





