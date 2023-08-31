import SwiftUI
import CoreData
import MessageUI

struct BarLineView: View {
    var entry:ScoreEntry
    var staff:Staff
    var staffLayoutSize:StaffLayoutSize

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.black)
                .frame(width: 1.0, height: 4.0 * Double(staffLayoutSize.lineSpacing))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
        }
        .frame(maxWidth: Double(staffLayoutSize.lineSpacing)  * 1.0)
        .border(Color.red)
    }
}

struct NoteHiliteView: View {
    @ObservedObject var entry:TimeSliceEntry
    var x:CGFloat
    var y:CGFloat
    var width:CGFloat
    
    var body: some View {
        VStack {
            if entry.hilite {
                //Text("HH")
                Ellipse()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: width, height: width)
                    .position(x: x, y:y)
            }
        }
    }
}

struct NotesView: View {
    @ObservedObject var notes:TimeSlice
    var staff:Staff
    var color: Color
    var lineSpacing:Double
    var noteWidth:Double
    var accidental:Int?
    
    init(staff:Staff, notes:TimeSlice, noteWidth:Double, lineSpacing: Double) {
        self.staff = staff
        self.notes = notes
        self.noteWidth = noteWidth
        self.color = Color.black
        self.lineSpacing = lineSpacing
    }
    
    func getAccidental(accidental:Int) -> String {
        if accidental < 0 {
            return "\u{266D}"
        }
        else {
            if accidental > 0 {
                return "\u{266F}"
            }
            else {
                return "\u{266E}"
            }
        }
    }
    
    struct LedgerLine:Hashable {
        var id = UUID()
        var offsetVertical:Double
    }
    
    func getLedgerLines(note:Note, noteWidth:Double, lineSpacing:Double) -> [LedgerLine] {
        var result:[LedgerLine] = []
        if note.midiNumber >= 81 { //A5
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * -1.0))
            if note.midiNumber >= 84 {
                result.append(LedgerLine(offsetVertical: 4 * lineSpacing * -1.0))
            }
            if note.midiNumber >= 88 {
                result.append(LedgerLine(offsetVertical: 5 * lineSpacing * -1.0))
            }
        }
        if note.midiNumber <= 60 {
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * 1.0))
            if note.midiNumber <= 58 {
                result.append(LedgerLine(offsetVertical: 4 * lineSpacing * 1.0))
            }
            if note.midiNumber <= 54 {
                result.append(LedgerLine(offsetVertical: 5 * lineSpacing * 1.0))
            }
        }
        return result
    }
    
    func getTimeSliceEntries() -> [TimeSliceEntry] {
        //        print("====Notes", notes.notes.count)
        //        for n in notes.notes {
        //            print("  ==Note", n.midiNumber, n.sequence)
        //        }
        var result:[TimeSliceEntry] = []
        for n in self.notes.entries {
            //if n is Note {
                result.append(n)
            //}
        }
        return result
    }
    
    func NoteView(note:Note, noteFrameWidth:Double, geometry: GeometryProxy) -> some View {
        ZStack {
            let placement = note.getNotePlacement(staff: staff)
            let offsetFromStaffMiddle = placement.offsetFromStaffMidline
            let accidental = placement.accidental
            let noteEllipseMidpoint:Double = geometry.size.height/2.0 - Double(offsetFromStaffMiddle) * lineSpacing / 2.0
            let noteValueUnDotted = note.isDotted ? note.getValue() * 2.0/3.0 : note.getValue()
            
            if staff.staffNum == 0 {
                NoteHiliteView(entry: note, x: noteFrameWidth/2, y: noteEllipseMidpoint, width: noteWidth * 1.5)
            }

            if let accidental = accidental {
                let yOffset = accidental == 1 ? lineSpacing / 5 : 0.0
                Text(getAccidental(accidental: accidental))
                    .font(.system(size: lineSpacing * 3.0))
                    .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                    .position(x: noteFrameWidth/2 - lineSpacing * (notes.anyNotesRotated() ? 3.0 : 2.0),
                              y: noteEllipseMidpoint + yOffset)

            }
            //Note ellipse
            if note.noteTag == .inError {
                Text("X")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.red)
                    .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                    .position(x: noteFrameWidth/2, y: noteEllipseMidpoint)
            }
            else {
                if [Note.VALUE_QUARTER, Note.VALUE_QUAVER].contains(noteValueUnDotted )  {
                    Ellipse()
                    //Closed ellipse
                        .foregroundColor(note.getColor(staff: staff))
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                        .position(x: noteFrameWidth/2  - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                }
                if noteValueUnDotted == Note.VALUE_HALF || noteValueUnDotted == Note.VALUE_WHOLE {
                    Ellipse()
                    //Open ellipse
                        .stroke(note.getColor(staff: staff), lineWidth: 2)
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 0.9))
                        .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                }

                //dotted
                if note.isDotted {
                    //the dot needs to be moved off the note center to move the dot off a staff line
                    let yOffset = offsetFromStaffMiddle % 2 == 0 ? lineSpacing / 3.0 : 0
                    Ellipse()
                    //Open ellipse
                    //.stroke(color(note: note), lineWidth: 2)
                        .frame(width: noteWidth/3.0, height: noteWidth/3.0)
                        .position(x: noteFrameWidth/2 + noteWidth/0.75, y: noteEllipseMidpoint - yOffset)
                        .foregroundColor(note.getColor(staff: staff))
                }

                if !note.isOnlyRhythmNote {
                    if staff.type == .treble {
                        ForEach(getLedgerLines(note: note, noteWidth: noteWidth, lineSpacing: lineSpacing), id: \.id) { line in
                            let y = geometry.size.height/2.0 + line.offsetVertical
                            let x = noteFrameWidth/2 - noteWidth
                            Path { path in
                                path.move(to: CGPoint(x: x, y: y))
                                path.addLine(to: CGPoint(x: x + 2 * noteWidth, y: y))
                            }
                            .stroke(note.getColor(staff: staff), lineWidth: 1)
                            //.stroke(Color.red, lineWidth: 2)
                        }
                    }
                }
            }
        }
    }
    
    func RestView(entry:TimeSliceEntry, geometry:GeometryProxy) -> some View {
        ZStack {
//            if staff.staffNum == 0 {
            //this code casues the rest image to jump right when its hilighted.
//                NoteHiliteView(entry: entry, x: geometry.size.width/2, y: geometry.size.height/2, width: noteWidth * 1.5)
//            }
            
            Image("rest_quarter")
                .resizable()
                .scaledToFit()
                .frame(height: CGFloat(geometry.size.height/4))
                .padding()
            
            //.border(Color.red)
        }
        //.frame(width: CGFloat(geometry.size.width * 4))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let noteFrameWidth = geometry.size.width * 1.0 //center the note in the space allocated by the parent for this note's view

                ForEach(getTimeSliceEntries(), id: \.self) { entry in
                    VStack {
                        if entry is Note {
                            NoteView(note: entry as! Note, noteFrameWidth: noteFrameWidth, geometry: geometry)
                        }
                        if entry is Rest {
                            Spacer()
                            RestView(entry: entry, geometry: geometry)
                            Spacer()
                        }
                    }
                    //.border(Color.green)
                }
            }
        }
    }
}
