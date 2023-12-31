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
    @State var lastGestureTime:Date? = nil

    func drumView() -> some View {
        VStack {
            Image("drum_transparent")
                .resizable()
                .scaledToFit()
                .padding()
                //.frame(width: UIScreen.main.bounds.width / 4.0)
                //.padding()
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
            ///18Nov23 - useUpstrokeTaps - removed option - is now alwasy false
            ///Using the geture on iPhone is problematic. It generates 4-6 notifications per tap. Use use upstroke for phone
            if Settings.shared.useUpstrokeTaps { //}|| UIDevice.current.userInterfaceIdiom == .phone {
                ZStack {
                    drumView()
                        .frame(width: UIScreen.main.bounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2))

                }
                .padding()
                .onTapGesture {
                    ///Fires on up stroke
                    if isRecording {
                        invert.switchBorder()
                        ///Too much sound lag on phone so dont use sound
                        tapRecorder.makeTap(useSoundPlayer:Settings.shared.soundOnTaps) // && UIDevice.current.userInterfaceIdiom == .pad)
//                        tapCtr += 1

                    }
                }
            }
            else {
                ZStack {
                    drumView()
                }
                .frame(width: UIScreen.main.bounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2))
                .gesture(
                    ///Fires on downstroke
                    ///Min distance has to be 0 to notify on tap
                    DragGesture(minimumDistance: 0)
                    .onChanged({ gesture in
                        if isRecording {
                            ///iPhone seems to generate 4-6 notifictions on each tap. Maybe since this is a gesture?
                            ///So drop the notifictions that are too close together. < 0.10 seconds
                            var doTap = false
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                doTap = true
                            }
                            else {
                                if let lastTime = lastGestureTime {
                                    let diff = gesture.time.timeIntervalSince(lastTime)
                                    if diff > 0.20 {
                                        doTap = true
                                    }
                                    //print("================ Tap", tapCtr, "Do:", doTap, "time", gesture.time, "diff", diff )
                                }
                                else {
                                    doTap = true
                                }
                                
                            }
                            if doTap {
                                self.lastGestureTime = gesture.time
                                invert.switchBorder()
                                tapRecorder.makeTap(useSoundPlayer:Settings.shared.soundOnTaps)
                            }
                            tapCtr += 1
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





