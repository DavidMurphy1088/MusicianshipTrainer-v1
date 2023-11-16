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
    @State var tapCtr = 0
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
            if Settings.shared.useUpstrokeTaps || UIDevice.current.userInterfaceIdiom == .phone {
                ZStack {
                    drumView()
                }
                .padding()
                .onTapGesture {
                    ///Fires on up stroke
                    if isRecording {
                        invert.switchBorder()
                        ///Too much sound lag on phone so dont use sound
                        tapRecorder.makeTap(useSoundPlayer:Settings.shared.soundOnTaps && UIDevice.current.userInterfaceIdiom == .pad)
//                        tapCtr += 1

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
                    ///Cannot use on iPhone - it seems to generate 4-6 notifictions on each tap.
                    DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        if isRecording {
                            invert.switchBorder()
                            tapRecorder.makeTap(useSoundPlayer:Settings.shared.soundOnTaps)
//                            tapCtr += 1
                        }
                    })
                )
            }

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





