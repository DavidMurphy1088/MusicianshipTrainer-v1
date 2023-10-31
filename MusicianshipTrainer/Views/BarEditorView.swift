import Foundation
import SwiftUI

///Show the bar view based on the positions of the bar lines
struct BarEditorView: View {
    @ObservedObject var score:Score
    @ObservedObject var barEditor:BarEditor
    let lineSpacing:Double
    @State private var showHelp = false
    
    init (score:Score) {
        self.score = score
        self.barEditor = score.barEditor!
        self.lineSpacing = score.staffLayoutSize.lineSpacing
    }
    
    ///Return the bar index number and the start and end x span of the bar's postion on the UI
    func getPositions() -> [(Int, CGFloat, CGFloat)] {
        var barLineCovers:[(CGFloat, CGFloat)] = []
        for p in score.barLayoutPositions.positions {
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
            ZStack {
                ForEach(getPositions(), id: \.self.0) { indexAndPos in
                    let barWidth = (indexAndPos.2 - indexAndPos.1)
                    VStack {
                        if indexAndPos.0 < barEditor.selectedBarStates.count {
                            if barEditor.selectedBarStates[indexAndPos.0] {
                                if score.scoreEntries.count > 1 {
                                    Text("Delete Bar \(indexAndPos.0+1)").defaultTextStyle()
                                    HStack {
                                        Button(action: {
                                            barEditor.reWriteBar(targetBar: indexAndPos.0, way: .delete)
                                        }) {
                                            Image("delete_icon")
                                                .resizable()
                                                .foregroundColor(.red)
                                                .frame(width: iconWidth, height: iconWidth)
                                        }
                                        .padding()
                                        Button(action: {
                                            barEditor.reWriteBar(targetBar: indexAndPos.0, way: .doNothing)
                                        }) {
                                            Text("Cancel").defaultTextStyle()
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                    .position(x:indexAndPos.2 - barWidth/2.0, y:0)
                    .frame(height: lineSpacing * 12.0)
                    .border(Color.red)
                    
                    ///Hilite every bar with shading
                    GeometryReader { geometry in
                        if indexAndPos.0 < barEditor.selectedBarStates.count {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getColor(way: barEditor.selectedBarStates[indexAndPos.0]))
                                .frame(width: barWidth, height: lineSpacing * 8.0) //130
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
            
            .onAppear() {
                showHelp = true
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                    showHelp = false
                }
            }
            .popover(isPresented: $showHelp) {
                Text("Click any bar to select it. Then click the red cross to remove the bar.").padding(20)
            }
        }
    }
}
