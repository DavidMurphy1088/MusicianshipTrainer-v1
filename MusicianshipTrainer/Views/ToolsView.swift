import SwiftUI
import CoreData

struct ToolsView: View {
    let score:Score
    let helpMetronome:String
    let frameHeight = 120.0
    
    var body: some View {
        VStack {
            HStack {
                MetronomeView(score:score, helpText: helpMetronome, frameHeight: frameHeight)
                    //.padding(.horizontal)
                    .padding()
                VoiceCounterView(frameHeight: frameHeight)
                    //.padding(.horizontal)
                    .padding()
            }
        }
    }
}




