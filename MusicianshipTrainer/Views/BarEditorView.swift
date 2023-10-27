import Foundation
import SwiftUI

///Show the bar view based on the postions of the bar lines
struct BarEditorView: View {
    @ObservedObject var score:Score
    @ObservedObject var barEditor:BarEditor
    @ObservedObject var barLayoutPositions:BarLayoutPositions
    @State var isShowingText  = false
    let lineSpacing:Double
    
    ///Return the bar index number and the start and end x span of its postion on the UI
    func getPositions() -> [(Int, CGFloat, CGFloat)] {
        var barLineCovers:[(CGFloat, CGFloat)] = []
        for p in barLayoutPositions.positions {
            barLineCovers.append((p.value.minX, p.value.maxX))
        }
        let sortedBarLineCovers = barLineCovers.sorted{ $0.0 < $1.0}
        
        var barCovers:[(Int, CGFloat, CGFloat)] = []
        let edgeBarWidth = 40.0
        var nextX = edgeBarWidth

        for i in 0..<sortedBarLineCovers.count {
            barCovers.append((i, nextX, sortedBarLineCovers[i].0)) //sortedBarLineCovers[i].0))
            nextX = sortedBarLineCovers[i].1
        }
        barCovers.append((sortedBarLineCovers.count, nextX, nextX + edgeBarWidth * 3.0))
        return barCovers
    }
    
    func getColor(way:Bool) -> Color {
        return way ? Color.indigo.opacity(0.25) : Color.blue.opacity(0.1)
    }
                           
    var body: some View {
        if let barEditor = score.barEditor {
            let iconWidth = lineSpacing * 3.0
            ForEach(getPositions(), id: \.self.0) { indexAndPos in
                let barWidth = (indexAndPos.2 - indexAndPos.1)
                HStack {
                    if barEditor.states[indexAndPos.0] {
                        if score.scoreEntries.count > 1 {
                            Button(action: {
                                barEditor.reWriteBar(targetBar: indexAndPos.0, way: .delete)
                            }) {
                                VStack {
                                    Text("Delete Bar")
                                    Image(systemName: "delete.left")
                                        .resizable()
                                        .foregroundColor(.red)
                                        .frame(width: iconWidth, height: iconWidth)
                                 }
                            }
                            //.padding()
                        }
                        
//                        Button(action: {
//                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .beat)
//                        }) {
//                            HStack {
//                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
//                                    .resizable()
//                                    .frame(width: iconWidth, height: iconWidth)
//                            }
//                        }
//                        //.padding()
//
//                        Button(action: {
//                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .silent)
//                        }) {
//                            HStack {
//                                Image(systemName: "rectangle.slash")
//                                    .resizable()
//                                    .frame(width: iconWidth, height: iconWidth)
//                            }
//                        }
//                        //.padding()
//
//                        Button(action: {
//                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .original)
//                        }) {
//                            HStack {
//                                Image(systemName: "arrowshape.turn.up.backward")
//                                    .resizable()
//                                    .frame(width: iconWidth, height: iconWidth)
//                            }
//                        }
                        //.padding(.left, 20)
                    }
                }
                .position(x:indexAndPos.2 - barWidth/2.0, y:0)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getColor(way: barEditor.states[indexAndPos.0]))
                        .frame(width: barWidth, height: 130)
                        .onTapGesture {
                            barEditor.toggleState(indexAndPos.0)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .position(x:indexAndPos.2 - barWidth / 2.0, y:geometry.size.height / 2.0)
                }
            }
        }
    }
}
