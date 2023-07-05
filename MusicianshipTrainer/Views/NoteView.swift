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
        //.border(Color.red)
    }
}

struct NoteView: View {
    @ObservedObject var note:Note
    var staff:Staff
    var color: Color
    var lineSpacing:Double
    var noteWidth:Double
    var offsetFromStaffMiddle:Int
    
    init(staff:Staff, note:Note, noteWidth:Double, lineSpacing: Double, offsetFromStaffMiddle:Int) {
        self.staff = staff
        self.note = note
        self.noteWidth = noteWidth
        self.color = Color.black 
        self.lineSpacing = lineSpacing
        self.offsetFromStaffMiddle = offsetFromStaffMiddle
        log()
    }
    
    func log() {
        if noteWidth == 0 {
            
        }
        if note.sequence == 7 {
            
        }
        let val = note.isDotted ? note.getValue() * 2.0/3.0 : note.getValue()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let noteFrameWidth = geometry.size.width * 1.0 //center the note in the space allocated by the parent for this note's view
            //let noteRotation:Int = note.rotatated == true ? noteFrameWidth : 0
            let noteEllipseMidpoint:Double = geometry.size.height/2.0 - Double(offsetFromStaffMiddle) * lineSpacing / 2.0
            let noteValueUnDotted = note.isDotted ? note.getValue() * 2.0/3.0 : note.getValue()

            ZStack {
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
                        //.stroke(Color.black, lineWidth: note.value == 4 ? 0 : 2) // minim or use foreground color for 1/4 note
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
                    
                    //ledger line hack - totally not generalized :(
                    if !note.isOnlyRhythmNote {
                        if staff.type == .treble {
                            if note.midiNumber <= Note.MIDDLE_C {
                                //let xOffset:Double = UIDevice.current.userInterfaceIdiom == .phone ? -Double(lineSpacing) / 2.0 : noteFrameWidth / 6.0
                                let xOffset:Double = UIDevice.current.userInterfaceIdiom == .phone ? -Double(lineSpacing) / 2.0 : noteFrameWidth / 3.5
                                Path { path in
                                    path.move(to: CGPoint(x: (xOffset), y: noteEllipseMidpoint))
                                    path.addLine(to: CGPoint(x: (noteFrameWidth - xOffset), y: noteEllipseMidpoint))
                                }
                                .stroke(note.getColor(staff: staff), lineWidth: 1)
                            }
                        }
                    }
                }
                // hilite
                if note.hilite {
                    Ellipse()
                        .stroke(Color.blue, lineWidth: 3) // minim or use foreground color for 1/4 note
                        .frame(width: noteWidth * 1.8, height: CGFloat(Double(lineSpacing) * 1.8))
                        .position(x: noteFrameWidth/2, y: CGFloat(noteEllipseMidpoint))
                        //.opacity(Double(opacity))
                }
            }
            //.border(Color.green)
        }
    }
}
