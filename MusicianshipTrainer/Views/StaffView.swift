import SwiftUI
import CoreData
import MessageUI

struct StaffLinesView: View {
    @ObservedObject var staff:Staff
    var staffLayoutSize:StaffLayoutSize

    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                if staff.linesInStaff > 1 {
                    ForEach(-2..<3) { row in
                        Path { path in
                            let y:Double = (geometry.size.height / 2.0) + Double(row) * staffLayoutSize.lineSpacing
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        //.fill(Color(.black))
                        .stroke(Color.black, lineWidth: 1)
                    }
                }
                else {
                    Path { path in
                        let y:Double = geometry.size.height/2.0
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.black, lineWidth: 1)
                }
                
                // end of staff bar lines
                
                let x:Double = geometry.size.width - 2.0
                let top:Double = (geometry.size.height/2.0) + Double(2 * staffLayoutSize.lineSpacing)
                let bottom:Double = (geometry.size.height/2.0) - Double(2 * staffLayoutSize.lineSpacing)
                
                Path { path in
                    path.move(to: CGPoint(x: x, y: top))
                    path.addLine(to: CGPoint(x: x, y: bottom))
                }
                .stroke(Color.black, lineWidth: Double(staffLayoutSize.lineSpacing) / 3)
                let x1:Double = geometry.size.width - (Double(staffLayoutSize.lineSpacing) * 0.7)
                Path { path in
                    path.move(to: CGPoint(x: x1, y: top))
                    path.addLine(to: CGPoint(x: x1, y: bottom))
                }
                .stroke(Color.black, lineWidth: 1)
            }
        }
    }
}

struct TimeSignatureView: View {
    @ObservedObject var staff:Staff
    var timeSignature:TimeSignature
    var lineSpacing:Double
    var clefWidth:Double
    
    func fontSize(for height: CGFloat) -> CGFloat {
        // Calculate the font size based on the desired pixel height
        let desiredPixelHeight: CGFloat = 48.0
        let scaleFactor: CGFloat = 72.0 // 72 points per inch
        let points = (desiredPixelHeight * 72.0) / scaleFactor
        let scalingFactor = height / UIScreen.main.bounds.size.height
        return points * scalingFactor
    }

    var body: some View {
        //GeometryReader { geometry in
            let padding:Double = Double(lineSpacing) / 3.0
            let fontSize:Double = Double(lineSpacing) * (staff.linesInStaff == 1 ? 2.2 : 2.2)
            
            if timeSignature.isCommonTime {
                Text(" C")
                    .font(.custom("Times New Roman", size: fontSize * 1.5)).bold()
                //.font(.system(size: fontSize(for: geometry.size.height)))
            }
            else {
                VStack (spacing: 0) {
                    Text(" \(timeSignature.top)").font(.system(size: fontSize * 1.1)).padding(.vertical, -padding)
                    Text(" \(timeSignature.bottom)").font(.system(size: fontSize  * 1.1)).padding(.vertical, -padding)
                }
            }
        //}
    }
}

struct CleffView: View {
    @ObservedObject var staff:Staff
    @ObservedObject var lineSpacing:StaffLayoutSize

    var body: some View {
        HStack {
            if staff.type == StaffType.treble {
                VStack {
                    Text("\u{1d11e}").font(.system(size: CGFloat(lineSpacing.lineSpacing * 10)))
                        .padding(.top, 0.0)
                        .padding(.bottom, lineSpacing.lineSpacing * 1.0)
                }
                //.border(Color.red)
            }
            else {
                Text("\u{1d122}").font(.system(size: CGFloat(Double(lineSpacing.lineSpacing) * 6.5)))
            }
        }
        //.border(Color.green)
    }
}

struct KeySignatureView: View {
    @ObservedObject var score:Score
    var lineSpacing:Double
    var staffOffsets:[Int]
    
    func getWidthMultiplier() -> Double {
        var widthMultiplier = staffOffsets.count <= 2 ? 1.0 : 0.7
        if UIDevice.current.userInterfaceIdiom == .phone {
            widthMultiplier = widthMultiplier * 0.7
        }
        return widthMultiplier
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(staffOffsets, id: \.self) { offset in
                VStack {
                    Image("sharp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: lineSpacing * getWidthMultiplier())
                        .offset(y: 0 - Double(offset) * lineSpacing / 2.0)
                }
                .padding(0)
                .frame(width: lineSpacing * getWidthMultiplier())
                //.border(Color.blue)
            }
        }
    }
}

///Show the bar view based on the postions of the bar lines
struct BarManagerView: View {
    @ObservedObject var score:Score
    @ObservedObject var barManager:BarManager
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
        if let barManager = score.barManager {
            let iconWidth = lineSpacing * 2.0
            ForEach(getPositions(), id: \.self.0) { indexAndPos in
                let barWidth = (indexAndPos.2 - indexAndPos.1)
                HStack {
                    if barManager.states[indexAndPos.0] {
                        if score.scoreEntries.count > 1 {
                            Button(action: {
                                barManager.reWriteBar(targetBar: indexAndPos.0, way: .delete)
                            }) {
                                HStack {
                                    Image(systemName: "square.split.diagonal.2x2")
                                        .resizable()
                                        .frame(width: iconWidth, height: iconWidth)
                                }
                            }
                            //.padding()
                        }
                        
                        Button(action: {
                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .beat)
                        }) {
                            HStack {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    .resizable()
                                    .frame(width: iconWidth, height: iconWidth)
                                    .onTapGesture {
                                        isShowingText = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            isShowingText = false
                                        }
                                        
                                    }
                                
                            }
                        }
                        //.padding()
                        
                        Button(action: {
                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .silent)
                        }) {
                            HStack {
                                Image(systemName: "rectangle.slash")
                                    .resizable()
                                    .frame(width: iconWidth, height: iconWidth)
                            }
                        }
                        //.padding()
                        
                        Button(action: {
                            barManager.reWriteBar(targetBar: indexAndPos.0, way: .original)
                        }) {
                            HStack {
                                Image(systemName: "arrowshape.turn.up.backward")
                                    .resizable()
                                    .frame(width: iconWidth, height: iconWidth)
                            }
                        }
                        //.padding(.left, 20)
                    }
                }
                .position(x:indexAndPos.2 - barWidth/2.0, y:0)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getColor(way: barManager.states[indexAndPos.0]))
                        .frame(width: barWidth, height: 130)
                        .onTapGesture {
                            barManager.toggleState(indexAndPos.0)
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

struct StaffView: View {
    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    @ObservedObject var staffLayoutSize:StaffLayoutSize = StaffLayoutSize(lineSpacing: 0)
    
    @State private var rotationId: UUID = UUID()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var position: CGPoint = .zero
    var entryPositions:[Double] = []
    var totalDuration = 0.0
    
    init (score:Score, staff:Staff, staffLayoutSize:StaffLayoutSize) {
        self.score = score
        self.staff = staff
        self.staffLayoutSize = staffLayoutSize
    }
    
    func clefWidth() -> Double {
        return Double(staffLayoutSize.lineSpacing) * 3.0
    }
    
    func getNotes(entry:ScoreEntry) -> [Note] {
        if entry is TimeSlice {
            let ts = entry as! TimeSlice
            return ts.getTimeSliceNotes()
        }
        else {
            let n:[Note] = []
            return n
        }
    }
    
    func keySigOffsets(staff:Staff, keySignture:KeySignature) -> [Int] {
        var offsets:[Int] = []
        if staff.type == .treble {
            //Key Sig offsets on staff
            if keySignture.accidentalCount > 0 {
                offsets.append(4)
            }
            if keySignture.accidentalCount > 1 {
                offsets.append(1)
            }
            if keySignture.accidentalCount > 2 {
                offsets.append(5)
            }
            if keySignture.accidentalCount > 3 {
                offsets.append(2)
            }
            if keySignture.accidentalCount > 4 {
                offsets.append(-1)
            }
        }
        else {
            if keySignture.accidentalCount > 0 {
                offsets.append(2)
            }
            if keySignture.accidentalCount > 1 {
                offsets.append(-1)
            }
            if keySignture.accidentalCount > 2 {
                offsets.append(3)
            }
            if keySignture.accidentalCount > 3 {
                offsets.append(0)
            }
            if keySignture.accidentalCount > 4 {
                offsets.append(-3)
            }

        }
        return offsets
    }
    
    var body: some View {
        ZStack { // The staff lines view and everything else on the staff share the same space
            StaffLinesView(staff: staff, staffLayoutSize: staffLayoutSize)
                .frame(height: staffLayoutSize.getStaffHeight(score: score))
                //.border(Color .indigo, width: 3)
            HStack(spacing: 0) {
                if staff.linesInStaff != 1 {
                    CleffView(staff: staff, lineSpacing: staffLayoutSize)
                        .frame(height: staffLayoutSize.getStaffHeight(score: score))
                    //.border(Color.red)
                    if score.key.keySig.accidentalCount > 0 {
                        KeySignatureView(score: score, lineSpacing: staffLayoutSize.lineSpacing,
                                         staffOffsets: keySigOffsets(staff: staff, keySignture: score.key.keySig))
                            .frame(height: staffLayoutSize.getStaffHeight(score: score))
                    }
                }

                TimeSignatureView(staff: staff, timeSignature: score.timeSignature, lineSpacing: staffLayoutSize.lineSpacing, clefWidth: clefWidth()/1.0)
                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                //    .border(Color.red)

                ScoreEntriesView(score: score, staff: staff, lineSpacing: staffLayoutSize)
                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                    .coordinateSpace(name: "StaffNotesView")
            }
            
        }
        .coordinateSpace(name: "StaffView.ZStack")
        .frame(height: staffLayoutSize.getStaffHeight(score: score))
        //.border(Color .blue, width: 2)
    }
}

