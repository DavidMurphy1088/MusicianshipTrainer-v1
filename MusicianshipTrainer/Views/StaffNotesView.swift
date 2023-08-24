import SwiftUI
import CoreData

struct TimeSliceLabelView: View {
    var score:Score
    var staff:Staff
    @ObservedObject var timeSlice:TimeSlice
    //@State var staffHeight:Double
    //var staffLayoutSize:StaffLayoutSize
    
    var body: some View {
        ZStack {
            if staff.staffNum == 0 {
                if let tag = timeSlice.tagHigh {
                    VStack {
                        //Text(" ")
                        Text(tag).font(.custom("TimesNewRomanPS-BoldMT", size: 24))
                            //.padding(.top, 0) //lineSpacing.value / 2.0)
                        Spacer()
                    }
                }
                if let tag = timeSlice.tagLow {
                    VStack {
                        Spacer()
                        Text(tag).font(.custom("TimesNewRomanPS-BoldMT", size: 24))
                            //.padding(.bottom, 0)//lineSpacing.value / 2.0)
                    }
                }
            }
        }
        //.frame(width: 4.0 * CGFloat(lineSpacing.value), height: staffHeight)
        //.frame(height: staffHeight)
    }
}

struct StemView: View {
    @State var score: Score
    @State var staff: Staff
    @State var notePositionLayout: NoteLayoutPositions
    @State var notes: TimeSlice
    @ObservedObject var lineSpacing:StaffLayoutSize
    
    func stemDirection(note:Note) -> Double {
        if note.isOnlyRhythmNote {
            return -1.0
        }
        else {
            return note.midiNumber < 70 ? -1.0 : 1.0 //1 => stem down. below or at B flat
        }
    }
    
    func getStemLength() -> Double {
        let len = lineSpacing.lineSpacing * 3.5
        //print(s, "      StemView:: length:", len, lineSpacing.lineSpacing)
        return len
    }
    
    func getNoteWidth() -> Double {
        //print("      StemView:: spacing", lineSpacing.value)
        return lineSpacing.lineSpacing * 1.2
    }

    func getFurthestFromMidline(noteArray:[Note]) -> Note {
        var furthest:Note = Note(num: 0)
        var maxDist = 0
        for note in noteArray {
            let distance = abs(note.getNotePlacement(staff: staff).offsetFromStaffMidline)
            if distance > maxDist {
                maxDist = distance
                furthest = note
            }
        }
        return furthest
    }
    
    func log(note:Note) -> Bool {
//        print(self.notes.count, note.midiNumber, self.lineSpacing.lineSpacing, "offset", notes[0].noteOffsetFromMiddle(staff: staff).offsetFromStaffMidline)
        return true
    }
    
    func midPointXOffset(notes:TimeSlice, staff:Staff, stemDirection:Double) -> Double {
        if notes.anyNotesRotated() {
            for n in notes.notes {
                if n.rotated {
                    if n.midiNumber < staff.middleNoteValue {
                        ///Normally the up stem goes to the right of the note. But if there is a left rotated note we want the stem to go thru the middle of the two notes
                        return -1.0 * getNoteWidth()
                    }
                }
            }
            return (stemDirection * -1.0 * getNoteWidth())
        }
        else {
            return (stemDirection * -1.0 * getNoteWidth())
        }
    }

    var body: some View {
        GeometryReader { geo in
            VStack {
                if notes.notes.count < 2 {
                    ///Draw in the stem lines for all notes under the current stem line if this is one.
                    ///For a group of notes under a quaver beam the the stem direction (and later length...) is determined by only one note in the group
                    let startNote = notes.notes[0].getBeamStartNote(score: score, np: notePositionLayout)
                    let inErrorAjdust = notes.notes[0].noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                    if startNote.getValue() != Note.VALUE_WHOLE {
                        //Note this code eventually has to go adjust the stem length for notes under a quaver beam
                        //3.5 lines is a full length stem
                        let stemDirection = stemDirection(note: startNote)
                        //let midX = geo.size.width / 2.0 + (stemDirection * -1.0 * noteWidth / 2.0)
                        let midX = (geo.size.width + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection))) / 2.0
                        let midY = geo.size.height / 2.0
                        //let offsetY = Double(offsetFromStaffMiddle) * 0.5 * lineSpacing.lineSpacing + inErrorAjdust
                        let offsetY = CGFloat(notes.notes[0].getNotePlacement(staff: staff).offsetFromStaffMidline) * 0.5 * lineSpacing.lineSpacing + inErrorAjdust
                        Path { path in
                            path.move(to: CGPoint(x: midX, y: midY - offsetY))
                            path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                        }
                        .stroke(notes.notes[0].getColor(staff: staff), lineWidth: 1)
                    }
                }
                else {
                    ///This code assumes the stem for a chord wont (yet) be under a quaver beam
                    let furthestFromMidline = self.getFurthestFromMidline(noteArray: self.notes.notes)
                    let stemDirection = stemDirection(note: furthestFromMidline)
                    let midX:Double = (geo.size.width + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection))) / 2.0
                    let midY = geo.size.height / 2.0
                    let inErrorAjdust = 0.0 //note.noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                    ZStack {
                        ForEach(notes.notes, id: \.self) { note in
                            if note.getValue() != Note.VALUE_WHOLE {
                                let offsetY = CGFloat(note.getNotePlacement(staff: staff).offsetFromStaffMidline) * 0.5 * lineSpacing.lineSpacing + inErrorAjdust
                                Path { path in
                                    path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                    path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                                }
                                .stroke(notes.notes[0].getColor(staff: staff), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct StaffNotesView: View {
    @ObservedObject var noteLayoutPositions:NoteLayoutPositions
    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    @ObservedObject var staffLayoutSize:StaffLayoutSize
    
    static var viewNum:Int = 0
    let noteOffsetsInStaffByKey = NoteOffsetsInStaffByKey()
    let viewNum:Int
    
    init(score:Score, staff:Staff, lineSpacing:StaffLayoutSize) {
        self.score = score        
        self.staff = staff
        self.staffLayoutSize = lineSpacing
        self.noteLayoutPositions = staff.noteLayoutPositions
        StaffNotesView.viewNum += 1
        self.viewNum = StaffNotesView.viewNum
    }
        
    func getNote(entry:ScoreEntry) -> Note? {
        if entry is TimeSlice {
            if let notes = entry.getNotes() {
                if notes.count > 0 {
                    return notes[0]
                }
            }
        }
        return nil
    }
    
    func getBeamLine(endNote:Note, noteWidth:Double, startNote:Note, stemLength:Double) -> (CGPoint, CGPoint)? {
        var stemDirection:Double // = startNote.midiNumber < 71 ? -1.0 : 1.0
        if endNote.isOnlyRhythmNote {
            stemDirection = -1.0
        }
        else {
            stemDirection = startNote.midiNumber < 71 ? -1.0 : 1.0
        }

        let endNotePos = noteLayoutPositions.positions[endNote]
        if let endNotePos = endNotePos {
            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
            
            let endPitchOffset = endNote.getNotePlacement(staff: staff).offsetFromStaffMidline
            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * getLineSpacing() * -0.5)
            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
            
            //start note
            let startNotePos = noteLayoutPositions.positions[startNote]
            if let startNotePos = startNotePos {
                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
                let startPitchOffset = startNote.getNotePlacement(staff: staff).offsetFromStaffMidline
                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * getLineSpacing() * -0.5)
                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
                let p1 = CGPoint(x:xEndMid, y: yEndNoteStemTip)
                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
//                print("-----------getBeamLine forEndNote", endNote.sequence, "pos count", noteLayoutPositions.positions.count, "line", p1, p2)
//                print("  endNote:", String(format: "%.3f", endNotePos.minX), " startNote", String(format: "%.3f", startNotePos.minX))
                return (p1, p2)
            }
        }
        return nil
    }
    
    func highestNote(entry:ScoreEntry) -> Note? {
        let notes = entry.getNotes()
        if notes != nil {
            if notes!.count == 1 {
                return notes![0]
            }
            else {
                let staffNotes:[Note]
                if staff.type == .treble {
                    staffNotes = notes!.filter { $0.midiNumber >= Note.MIDDLE_C}
                }
                else {
                    staffNotes = notes!.filter { $0.midiNumber < Note.MIDDLE_C}
                }
                if staffNotes.count > 0 {
                    let sorted = staffNotes.sorted { $0.midiNumber > $1.midiNumber }
                    return sorted[0]
                }
            }
        }
        return nil
    }
    
    func getLineSpacing() -> Double {
        return self.staffLayoutSize.lineSpacing
    }

//    func log(notes: [Note : CGRect]) {
//        for n in notes.keys {
//            print("++++++Note seq", n.sequence, "midi:", n.midiNumber, n.getValue(), "\tBeamType:", n.beamType, "\tendNote:", n.beamEndNote?.midiNumber ?? "")
//            let re = notes[n]
//            //print ("   ", re)
//        }
//
//    }
    
    var body: some View {
        ZStack { //ZStack - notes and quaver beam drawing shares same space
            //let lineSpacing = self.getLineSpacing()
            let noteWidth = getLineSpacing() * 1.2
            HStack(spacing: 0) { //HStack - score entries display along the staff
                ForEach(score.scoreEntries, id: \.self) { entry in
                    VStack { //VStack - required in forEach closure
                        if entry is TimeSlice {
                            let notes = entry as! TimeSlice
                            ZStack { // Each note frame in the timeslice shares the same same vertical space
                                //let notes = getNotes(entry: entry)
                                NotesView(staff: staff,
                                         notes: notes,
                                         noteWidth: noteWidth,
                                         lineSpacing: staffLayoutSize.lineSpacing)
                                .background(GeometryReader { geometry in
                                    ///record and store the note's postion so we can later draw its stems which maybe dependent on the note being in a quaver group with a quaver beam
                                    Color.clear
                                        .onAppear {
                                            if staff.staffNum == 0 {
                                                noteLayoutPositions.storePosition(note: notes.notes[0],rect: geometry.frame(in: .named("HStack")), cord: "HStack")
                                            }
                                        }
                                        .onChange(of: staffLayoutSize.lineSpacing) { newValue in
                                             if staff.staffNum == 0 {
                                                 noteLayoutPositions.storePosition(note: notes.notes[0],rect: geometry.frame(in: .named("HStack")), cord: "HStack")
                                            }
                                        }
                                })
                                
                                StemView(score:score,
                                         staff:staff,
                                         notePositionLayout: noteLayoutPositions,
                                         notes: notes,
                                         lineSpacing: staffLayoutSize)

                                TimeSliceLabelView(score:score, staff:staff, timeSlice: entry as! TimeSlice)
                                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                            }
                        }
                        if entry is BarLine {
                            BarLineView(entry: entry, staff: staff, staffLayoutSize: staffLayoutSize)
                                .frame(height: staffLayoutSize.getStaffHeight(score: score))
                                //.border(Color.green)
                        }
                    }
                    .coordinateSpace(name: "VStack")
                    //IMPORTANT - keep this since the quaver beam code needs to know exactly the note view width
                }
                .coordinateSpace(name: "ForEach")
            }
            .coordinateSpace(name: "HStack")

            // ==================== Quaver beams =================
            
            if staff.staffNum == 0 {
                GeometryReader { geo in
                    ZStack {
                        ZStack {
                            //let log = log(notes: noteLayoutPositions.positions)
                            ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.sequence < $1.key.sequence }), id: \.key) {
                                endNote, endNotePos in
                                if endNote.beamType == .end {
                                    let startNote = endNote.getBeamStartNote(score: score, np:noteLayoutPositions)
                                    if let line = getBeamLine(endNote: endNote, noteWidth: noteWidth, startNote: startNote, stemLength: self.staffLayoutSize.lineSpacing * 3.5) {
                                        Path { path in
                                            path.move(to: CGPoint(x: line.0.x, y: line.0.y))
                                            path.addLine(to: CGPoint(x: line.1.x, y: line.1.y))
                                        }
                                        .stroke(endNote.getColor(staff: staff), lineWidth: 2)
                                    }
                                }
                            }
                        }
                        //.border(Color .blue)
                        .padding(.horizontal, 0)
                    }
                    //.border(Color .orange)
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, 0)
                //.border(Color .green)
            }
        }
        .coordinateSpace(name: "ZStack0")
        .onAppear() {
            //print("StaffNotesView .onAppear: num:", viewNum, "\tlineSpacing:", staffLayoutSize.lineSpacing)
        }
        .onDisappear() {
           // NoteLayoutPositions.reset()
        }
    }
    
}

