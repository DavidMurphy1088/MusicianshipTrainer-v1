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
    @State var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "TappingView")
    @State private var tapRecords: [CGPoint] = []
    @State var ctr = 0
    @ObservedObject var invert:Invert = Invert()
    @State private var isScaled = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    Image("drum_transparent")
                        .resizable()
                        .scaledToFit()
                        .padding()
                        //.border(invert.invert ? Color.accentColor : Color.accentColor, width: invert.invert ? 2 : 12)
                        .frame(width: geometry.size.width / 4.0)
                        .padding()
                        .clipShape(Circle())
                        .padding()
                        .overlay(Circle().stroke(invert.invert ? Color.white : Color.black, lineWidth: 4))
                        .shadow(radius: 10)
                        .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
                    
                    if true && isRecording {
                        if tapRecorder.enableRecordingLight {
                            Image(systemName: "stop.circle")
                                .foregroundColor(Color.red)
                                .font(.system(size: isScaled ? 70 : 50))
                                //.animation(Animation.easeInOut(duration: 1.0).repeatForever()) // Animates forever
                                //.position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
                                .onAppear {
                                    self.isScaled.toggle()
                                }
                        }
                    }
                }
            }
            .onTapGesture {
                if isRecording {
                    invert.rev()
                    tapRecorder.makeTap()
                }
            }
            .padding(.bottom, 0) 
        }
        //.border(.red)
    }
}





