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
    var staffOffset:Int
    
    var body: some View {
        //if score.key.keySig.accidentalCount > 0 {
        GeometryReader { geometry in
            VStack {
                Image("sharp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: lineSpacing)
                    .position(CGPoint(x: geometry.size.width/2.0, y: geometry.size.height/2.0 - Double(staffOffset) * lineSpacing / 2.0))
            }
            //.border(Color.blue)
        }
        .frame(width: lineSpacing * 1.5)
    }
}

struct StaffView: View {
    //let id = UUID()
    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    //var staffHeight:Double
    @ObservedObject var staffLayoutSize:StaffLayoutSize = StaffLayoutSize(lineSpacing: 0)
    //@ObservedObject var noteLayoutPositions:NoteLayoutPositions

    @State private var rotationId: UUID = UUID()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var position: CGPoint = .zero
    var entryPositions:[Double] = []
    var totalDuration = 0.0

    init (score:Score, staff:Staff, staffLayoutSize:StaffLayoutSize) {
        self.score = score
        self.staff = staff
        //self.staffHeight = staffHeight
        self.staffLayoutSize = staffLayoutSize
        //print("  StaffView init::lineSpace", lineSpacing)
    }
    
    func clefWidth() -> Double {
        return Double(staffLayoutSize.lineSpacing) * 3.0
    }
    
    func getNotes(entry:ScoreEntry) -> [Note] {
        if entry is TimeSlice {
            let ts = entry as! TimeSlice
            return ts.notes
        }
        else {
            let n:[Note] = []
            return n
        }
    }
    
//    func getLineSpacing() -> Double {
//        //print("  StaffView body::lineSpace", lineSpacing)
//        return lineSpacing.value
//    }

    var body: some View {
        ZStack { // The staff lines view and everything else on the staff share the same space
            StaffLinesView(staff: staff, staffLayoutSize: staffLayoutSize)
                .frame(height: staffLayoutSize.getStaffHeight(score: score))
                //.border(Color .purple, width: 2)
            
            HStack(spacing: 0) {
                if staff.linesInStaff != 1 {
                    CleffView(staff: staff, lineSpacing: staffLayoutSize)
                        .frame(height: staffLayoutSize.getStaffHeight(score: score))
                    //.border(Color.red)
                    if score.key.keySig.accidentalCount != 0 {
                        KeySignatureView(score: score, lineSpacing: staffLayoutSize.lineSpacing, staffOffset: staff.type == .treble ? 4 : 2)
                            .frame(height: staffLayoutSize.getStaffHeight(score: score))
                    }
                }

                TimeSignatureView(staff: staff, timeSignature: score.timeSignature, lineSpacing: staffLayoutSize.lineSpacing, clefWidth: clefWidth()/1.0)
                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                //    .border(Color.red)

                StaffNotesView(score: score, staff: staff, lineSpacing: staffLayoutSize)
                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                //Text("      ")
            }
        }
        .frame(height: staffLayoutSize.getStaffHeight(score: score))
        //.border(Color .blue, width: 2)
    }
}

