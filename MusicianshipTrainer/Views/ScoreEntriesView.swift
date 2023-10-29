import SwiftUI
import CoreData

struct TimeSliceLabelView: View {
    var score:Score
    var staff:Staff
    @ObservedObject var timeSlice:TimeSlice
    @State var showPopover = true
    
    var body: some View {
        ZStack {
            if staff.staffNum == 0 {
                if let tagHighContent = timeSlice.tagHigh?.content {
                    VStack {
                        Text(tagHighContent).font(.custom("TimesNewRomanPS-BoldMT", size: 24))
                        Spacer()
                    }
                    .popover(isPresented: $showPopover) {
                        Text("C# E G#").padding()
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
        .onAppear() {
            showPopover = timeSlice.tagHigh?.popup != nil
        }
        //.frame(width: 4.0 * CGFloat(lineSpacing.value), height: staffHeight)
        //.frame(height: staffHeight)
    }
}

struct StemView: View {
    @State var score: Score
    @State var staff: Staff
    @State var notePositionLayout: NoteLayoutPositions
    var notes: [Note]
    @ObservedObject var lineSpacing:StaffLayoutSize
    
    func getStemLength() -> Double {
        var len = 0.0
        if notes.count > 0 {
            len = notes[0].stemLength * lineSpacing.lineSpacing
        }
        return len
    }
    
    func getNoteWidth() -> Double {
        return lineSpacing.lineSpacing * 1.2
    }

    func midPointXOffset(notes:[Note], staff:Staff, stemDirection:Double) -> Double {
        for n in notes {
            if n.rotated {
                if n.midiNumber < staff.middleNoteValue {
                    ///Normally the up stem goes to the right of the note. But if there is a left rotated note we want the stem to go thru the middle of the two notes
                    return -1.0 * getNoteWidth()
                }
            }
        }
        return (stemDirection * -1.0 * getNoteWidth())
    }

//    func log(_ ctx:String) -> Bool {
//        return true
//    }
//
    func getStaffNotes(staff:Staff) -> [Note] {
        var notes:[Note] = []
        for n in self.notes {
            if n.staffNum == staff.staffNum {
                notes.append(n)
            }
        }
        return notes
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                let staffNotes = getStaffNotes(staff: staff)
                if staffNotes.count > 0 {
                    if staffNotes.count <= 1 {
                        ///Draw in the stem lines for all notes under the current stem line if this is one.
                        ///For a group of notes under a quaver beam the the stem direction (and later length...) is determined by only one note in the group
                        let startNote = staffNotes[0].getBeamStartNote(score: score, np: notePositionLayout)
                        let inErrorAjdust = 0.0 //notes.notes[0].noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                        if startNote.getValue() != Note.VALUE_WHOLE {
                            //if startNote.debug("VIEW staff:\(staff.staffNum)") {
                                //Note this code eventually has to go adjust the stem length for notes under a quaver beam
                                //3.5 lines is a full length stem
                                let stemDirection = startNote.stemDirection == .up ? -1.0 : 1.0 //stemDirection(note: startNote)
                                //let midX = geo.size.width / 2.0 + (stemDirection * -1.0 * noteWidth / 2.0)
                                let midX = (geo.size.width + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection))) / 2.0
                                let midY = geo.size.height / 2.0
                                let offsetY = CGFloat(notes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline) * 0.5 * lineSpacing.lineSpacing + inErrorAjdust
                                Path { path in
                                    path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                    path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                                }
                                .stroke(notes[0].getColor(staff: staff), lineWidth: 1.5)
                            //}
                        }
                    }
                    else {
                        ///This code assumes the stem for a chord wont (yet) be under a quaver beam
                        //let furthestFromMidline = self.getFurthestFromMidline(noteArray: staffNotes)

                        ZStack {
                            ForEach(staffNotes) { note in
                                let pp = note.getNoteDisplayCharacteristics(staff: staff)
                            
                                let stemDirection = note.stemDirection == .up ? -1.0 : 1.0 //stemDirection(note: furthestFromMidline)
                                let midX:Double = (geo.size.width + (midPointXOffset(notes: staffNotes, staff: staff, stemDirection: stemDirection))) / 2.0
                                let midY = geo.size.height / 2.0
                                let inErrorAjdust = 0.0 //note.noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                                
                                if note.getValue() != Note.VALUE_WHOLE {
                                    let offsetY = CGFloat(note.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline) * 0.5 * lineSpacing.lineSpacing + inErrorAjdust
                                    Path { path in
                                        path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                        path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                                    }
                                    .stroke(staffNotes[0].getColor(staff: staff), lineWidth: 1.5)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ScoreEntriesView: View {
    @ObservedObject var noteLayoutPositions:NoteLayoutPositions
    @ObservedObject var barLayoutPositions:BarLayoutPositions

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
        self.barLayoutPositions = score.barLayoutPositions
        ScoreEntriesView.viewNum += 1
        self.viewNum = ScoreEntriesView.viewNum
    }
        
    func getNote(entry:ScoreEntry) -> Note? {
        if entry is TimeSlice {
            //if let
                let notes = entry.getTimeSliceNotes()
                if notes.count > 0 {
                    return notes[0]
                }
            //}
        }
        return nil
    }
    
    func getBeamLine(endNote:Note, noteWidth:Double, startNote:Note, stemLength:Double) -> (CGPoint, CGPoint)? {
        let stemDirection:Double = startNote.stemDirection == .up ? -1.0 : 1.0
//        if endNote.isOnlyRhythmNote {
//            stemDirection = -1.0
//        }
//        else {
//            stemDirection = startNote.midiNumber < 71 ? -1.0 : 1.0
//        }

        let endNotePos = noteLayoutPositions.positions[endNote]
        if let endNotePos = endNotePos {
            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
            
            let endPitchOffset = endNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * getLineSpacing() * -0.5)
            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
            
            //start note
            let startNotePos = noteLayoutPositions.positions[startNote]
            if let startNotePos = startNotePos {
                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
                let startPitchOffset = startNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * getLineSpacing() * -0.5)
                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
                let p1 = CGPoint(x:xEndMid, y: yEndNoteStemTip)
                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
                return (p1, p2)
            }
        }
        return nil
    }
    
    func highestNote(entry:ScoreEntry) -> Note? {
        let notes = entry.getTimeSliceNotes()
        //if notes != nil {
            if notes.count == 1 {
                return notes[0]
            }
            else {
                let staffNotes:[Note]
                if staff.type == .treble {
                    staffNotes = notes.filter { $0.midiNumber >= Note.MIDDLE_C}
                }
                else {
                    staffNotes = notes.filter { $0.midiNumber < Note.MIDDLE_C}
                }
                if staffNotes.count > 0 {
                    let sorted = staffNotes.sorted { $0.midiNumber > $1.midiNumber }
                    return sorted[0]
                }
            }
        //}
        return nil
    }
    
    func getLineSpacing() -> Double {
        return self.staffLayoutSize.lineSpacing
    }

    func getQuaverImage(note:Note) -> Image {
        return Image(note.midiNumber > 71 ? "quaver_arm_flipped_grayscale" : "quaver_arm_grayscale")
    }

    func quaverBeamView(line: (CGPoint, CGPoint), startNote:Note, endNote:Note, lineSpacing: Double) -> some View {
        ZStack {
            if startNote.sequence == endNote.sequence {
                //An unpaired quaver
                let height = lineSpacing * 4.5
                let width = height / 3.0
                let flippedHeightOffset = startNote.midiNumber > 71 ? height / 2.0 : 0.0
                getQuaverImage(note:startNote)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(startNote.getColor(staff: staff))
                    .scaledToFit()
                    .frame(height: height)
                    .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset)
                
                if endNote.getValue() == Note.VALUE_SEMIQUAVER {
                    getQuaverImage(note:startNote)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(startNote.getColor(staff: staff))
                        .scaledToFit()
                        .frame(height: height)
                        .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset + lineSpacing)
                }
            }
            else {
                //A paired quaver
                Path { path in
                    path.move(to: CGPoint(x: line.0.x, y: line.0.y))
                    path.addLine(to: CGPoint(x: line.1.x, y: line.1.y))
                }
                .stroke(endNote.getColor(staff: staff), lineWidth: 3)
                //.stroke(lineWidth: 3)
            }
        }
    }
    
    var body: some View {
        ZStack { //ZStack - notes and quaver beam drawing shares same space
            //let lineSpacing = self.getLineSpacing()
            let noteWidth = getLineSpacing() * 1.2
            HStack(spacing: 0) { //HStack - score entries display along the staff
                ForEach(score.scoreEntries) { entry in
                    ZStack { //VStack - required in forEach closure
                        if entry is TimeSlice {
                            let entries = entry as! TimeSlice
                            ZStack { // Each note frame in the timeslice shares the same same vertical space
                                TimeSliceView(staff: staff,
                                         timeSlice: entries,
                                         noteWidth: noteWidth,
                                         lineSpacing: staffLayoutSize.lineSpacing)
                                //.border(Color.green)
                                .background(GeometryReader { geometry in
                                    ///Record and store the note's postion so we can later draw its stems which maybe dependent on the note being in a quaver group with a quaver beam
                                    Color.clear
                                        .onAppear {
                                            if staff.staffNum == 0 {
                                                noteLayoutPositions.storePosition(notes: entries.getTimeSliceNotes(),rect: geometry.frame(in: .named("HStack")))
                                            }
                                        }
                                        .onChange(of: staffLayoutSize.lineSpacing) { newValue in
                                             if staff.staffNum == 0 {
                                                 noteLayoutPositions.storePosition(notes: entries.getTimeSliceNotes(),rect: geometry.frame(in: .named("HStack")))
                                            }
                                        }
                                })

                                StemView(score:score,
                                         staff:staff,
                                         notePositionLayout: noteLayoutPositions,
                                         notes: entries.getTimeSliceNotes(),
                                         lineSpacing: staffLayoutSize)

                                TimeSliceLabelView(score:score, staff:staff, timeSlice: entry as! TimeSlice)
                                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                            }
                        }
                        if entry is BarLine {
                            GeometryReader { geometry in
                                BarLineView(entry: entry, staff: staff, staffLayoutSize: staffLayoutSize)
                                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                                    //.border(Color .red)
                                    .onAppear {
                                        if staff.staffNum == 0 {
                                            let barLine = entry as! BarLine
                                            barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onAppear")
                                        }
                                    }
                                    .onChange(of: staffLayoutSize.lineSpacing) { newValue in
                                        if staff.staffNum == 0 {
                                            let barLine = entry as! BarLine
                                            barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onChange")
                                        }
                                    }
                            }
                        }
                    }
                    .coordinateSpace(name: "VStack")
                    //IMPORTANT - keep this since the quaver beam code needs to know exactly the note view width
                }
                //.coordinateSpace(name: "ForEach")
                ///Spacing before end of staff
                Text(" ")
                    .frame(width:1.5 * noteWidth)
            }
            .coordinateSpace(name: "HStack")

            // ---------- Quaver beams ------------
            
            if staff.staffNum == 0 {
                GeometryReader { geo in
                    ZStack {
                        ZStack {
                            //let log = log(noteLayoutPositions: noteLayoutPositions)
                            ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.sequence < $1.key.sequence }), id: \.key.id) {
                                endNote, endNotePos in
                                if endNote.beamType == .end {
                                    let startNote = endNote.getBeamStartNote(score: score, np:noteLayoutPositions)
                                    if let line = getBeamLine(endNote: endNote, noteWidth: noteWidth,
                                                              startNote: startNote, stemLength:
                                                                self.staffLayoutSize.lineSpacing * 3.5) {
                                        quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: staffLayoutSize.lineSpacing)
                                    }
                                }
                            }
                        }
                        //.border(Color .red)
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
        }
        .onDisappear() {
           // NoteLayoutPositions.reset()
        }
    }
    
}

