import SwiftUI
import CoreData

struct PianoView: View {
    let whiteKeyCount = 7
    @ObservedObject var whiteKeys:WhiteKeys

    var body: some View {
        GeometryReader { geometry in
            let edgePadding = geometry.size.width * 0.1
            let whiteKeyWidth:CGFloat = (geometry.size.width - 2 * edgePadding) / CGFloat(whiteKeyCount)
            let whiteKeyHeight:CGFloat = geometry.size.height / 2.0
            let blackKeyWidth:CGFloat = whiteKeyWidth * 8/10
            let blackKeyHeight:CGFloat = whiteKeyHeight * 1/2
            VStack {
                ZStack {
                    ForEach(0..<whiteKeys.keys.count) { col in
                        Rectangle()
                            .foregroundColor(whiteKeys.keys[col].pressed ? .gray : .white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .position(x: edgePadding + (CGFloat(col) * whiteKeyWidth) + whiteKeyWidth/2, y: whiteKeyHeight/2) //.pos is center of rect
                            .onTapGesture {
                                DispatchQueue.global(qos: .userInitiated).async {
                                    //SoundGenerator.soundGenerator.playNote(notePitch: whiteKeys.keys[col].pitch)
                                    for key in self.whiteKeys.keys {
                                        key.pressed = false
                                    }
                                    whiteKeys.keys[col].pressed = true
                                    self.whiteKeys.changed.toggle()
                                }
                            }
                    }
                    
                    ForEach(0..<whiteKeyCount-1) { col in
                        if col != 2 {
                            Rectangle()
                                .foregroundColor(.black)
                            //                .overlay(
                            //                    Rectangle()
                            //                        .stroke(Color.black, lineWidth: 2)
                            //                )
                                .frame(width: blackKeyWidth, height: blackKeyHeight)
                                .position(x: edgePadding + (CGFloat(col+1) * whiteKeyWidth) + whiteKeyWidth/2 - blackKeyWidth/2 - 1, y: blackKeyHeight/2) //.pos is center of rect
                        }
                    }
                }
                Spacer()
            }
        }
    }
}
