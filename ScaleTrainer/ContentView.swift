import SwiftUI


struct PianoKey: View {
    var keyColor: Color
    var body: some View {
        Rectangle()
            .foregroundColor(keyColor)
            .cornerRadius(5)
            .border(.blue, width: 1)
    }
}

struct PianoView: View {
    private let whiteKeys = 12
    private let blackKeyOffsets = [0, 1, 3, 4, 5, 7]
    @State var offset = 0.0
    
    var body: some View {
        ZStack(alignment: .topLeading) { // Aligning to the top and leading edge
            // White keys
            HStack(spacing: 0) {
                ForEach(0..<whiteKeys) { _ in
                    PianoKey(keyColor: .white)
                        .frame(width: 60, height: 300)
                }
            }
            .border(Color.black, width: 1)
            
            // Black keys
            HStack(spacing: 0) {
                ForEach(0..<whiteKeys-1, id: \.self) { index in
                    if !blackKeyOffsets.contains(index) {
                        Spacer().frame(width: 60) // Spacing for white keys
                    } else {
                        let offset = 20.0
                        Spacer().frame(width: offset) // Spacing for white keys
                            .border(.red, width: 4)
                        PianoKey(keyColor: .black)
                            .frame(width: 40, height: 200)
                            //.offset(x: 30) // Adjust this offset for correct positioning
                    }
                }
            }
            .padding(.leading, 20) // Starting position of the first black key
        }
    }
}

struct ContentView: View {
    var body: some View {
        PianoView()
            .padding()
        //ScoreView()
    }
}

//@main
//struct PianoApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
