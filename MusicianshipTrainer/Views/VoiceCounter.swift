import SwiftUI
import CoreData

struct VoiceCounterView: View {
    var frameHeight:Double
    @ObservedObject var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "VoiceCounterView")

    var body: some View {
        VStack {
            Button(action: {
                let enabled = !metronome.speechEnabled
                metronome.setSpeechEnabled(enabled: enabled)
            }, label: {
                Image("voiceCount")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: frameHeight / 2.0)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: metronome.speechEnabled ? 10 : 0)
                            .stroke(metronome.speechEnabled ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .padding()
                    //.border(isImagePressed ? Color.red : Color.clear, width: 2)
            })

         }
        .frame(height: frameHeight)
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .background(UIGlobals.backgroundColor)
    }
}




