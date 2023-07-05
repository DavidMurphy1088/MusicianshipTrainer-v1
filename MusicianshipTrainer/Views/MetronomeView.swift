import SwiftUI
import CoreData

struct MetronomeView: View {
    let score:Score
    let helpText:String
    var frameHeight:Double
    @State var isPopupPresented:Bool = false
    @ObservedObject var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "MetronomeView")
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    if metronome.tickingIsActive == false {
                        metronome.startTicking(score: score)
                    }
                    else {
                        metronome.stopTicking()
                    }
                }, label: {
                    Image("metronome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: frameHeight / 2.0)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(metronome.tickingIsActive ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .padding()
                })

                Image("note_transparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .frame(width: frameHeight / 6.0)
                Text("=\(Int(metronome.tempo)) BPM")
            //}
            //HStack {
                Text(metronome.tempoName).padding()
                //}
                //.padding()
                
                if metronome.allowChangeTempo {
                    Slider(value: Binding<Double>(
                        get: { Double(metronome.tempo) },
                        set: {
                            metronome.setTempo(tempo: Int($0), context: "Metronome View, Slider change")
                        }
                    ), in: Double(metronome.tempoMinimumSetting)...Double(metronome.tempoMaximumSetting), step: 1)
                    .padding()
                }
                
                Button(action: {
                    isPopupPresented.toggle()
                }) {
                    VStack {
                        //VStack {
                            Text("Practice Tool")
                            //Text("Tool")
                        //}
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
                    }
                }
                .padding()
                .popover(isPresented: $isPopupPresented) { //, arrowEdge: .bottom) {
                    VStack {
                        Text(helpText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 1)
                            .padding()
                        )
                    .padding()
                }
            }
        }
        .frame(height: frameHeight)
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .background(UIGlobals.backgroundColor)

    }
}




