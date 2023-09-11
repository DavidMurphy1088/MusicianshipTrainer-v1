import Foundation
import AVKit
import AVFoundation

class ScoreEntry : ObservableObject, Hashable {
    let id = UUID()
    var sequence:Int = 0

    static func == (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func getTimeSliceEntries() -> [TimeSliceEntry] {
        var result:[TimeSliceEntry] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                //if entry is Note {
                    result.append(entry)
                //}
            }
        }
        return result
    }
    
    func getTimeSliceNotes() -> [Note] {
        var result:[Note] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                if entry is Note {
                    result.append(entry as! Note)
                }
            }
        }
        return result
    }
}


class StudentFeedback { //}: ObservableObject {
    var correct:Bool = false
    var indexInError:Int? = nil
    var feedbackExplanation:String? = nil
    var feedbackNote:String? = nil
    var tempo:Int? = nil
}

class StaffLayoutSize: ObservableObject {
    @Published var lineSpacing:Double
    static var lastHeight = 0.0
    init (lineSpacing:Double) {
        self.lineSpacing = lineSpacing
    }
    
    func setLineSpacing(_ v:Double) {
        DispatchQueue.main.async {
            self.lineSpacing = v
            //print("===============LineSpacing::SETVALUE======", v)
        }
    }
    
    func getStaffHeight(score:Score) -> Double {
        //leave enough space above and below the staff for the Timeslice view to show its tags
        let height = Double(score.getTotalStaffLineCount() + 2) * self.lineSpacing
        if height != StaffLayoutSize.lastHeight {
            //print("ScoreView::staffHeight", height)
            StaffLayoutSize.lastHeight = height
        }
        return height
    }
}

class Score : ObservableObject {
    let id:UUID
    //static var shared = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
    var timeSignature:TimeSignature
    let ledgerLineCount =  2 //3//4 is required to represent low E
    
    @Published var key:Key = Key(type: Key.KeyType.major, keySig: KeySignature(type: AccidentalType.sharp, keyName: ""))
    @Published var showNotes = true
    @Published var showFootnotes = false
    @Published var studentFeedback:StudentFeedback? = nil
    @Published var scoreEntries:[ScoreEntry] = []
    
    var staffs:[Staff] = []
    
    //var minorScaleType = Scale.MinorType.natural
    var recordedTempo:Int?
    static let maxTempo:Float = 200
    static let minTempo:Float = 30
    static let midTempo:Float = Score.minTempo + (Score.maxTempo - Score.minTempo) / 2.0
    static let slowTempo:Float = Score.minTempo + (Score.maxTempo - Score.minTempo) / 4.0
    
    private var totalStaffLineCount:Int = 0
    static var accSharp = "\u{266f}"
    static var accNatural = "\u{266e}"
    static var accFlat = "\u{266d}"
    var label:String? = nil
    
    enum NoteSize {
        case small
        case large
    }
    let noteSize:NoteSize
    
    init(timeSignature:TimeSignature, linesPerStaff:Int, noteSize:NoteSize) {
        self.id = UUID()
        self.timeSignature = timeSignature
        self.noteSize = noteSize
        totalStaffLineCount = linesPerStaff + (2*ledgerLineCount)
    }
    
    func getTotalStaffLineCount() -> Int {
        return self.totalStaffLineCount
    }
    
    func getAllTimeSlices() -> [TimeSlice] {
        var result:[TimeSlice] = []
        for scoreEntry in self.scoreEntries {
            if scoreEntry is TimeSlice {
                let ts = scoreEntry as! TimeSlice
                result.append(ts)
            }
        }
        return result
    }
    
    //return the first timeslice index of where the scores differ
    func getFirstDifferentTimeSlice(compareScore:Score) -> Int? {
         var result:Int? = nil
         var scoreCtr = 0

         let scoreTimeSlices = self.getAllTimeSlices()
         let compareTimeSlices = compareScore.getAllTimeSlices()

         for scoreTimeSlice in scoreTimeSlices {

             if compareTimeSlices.count <= scoreCtr {
                 result = scoreCtr
                 break
             }
             
             let compareEntry = compareTimeSlices[scoreCtr]
             let compareNotes = compareEntry.getTimeSliceEntries()
             let scoreNotes = scoreTimeSlice.getTimeSliceEntries()

//             if compareNotes == nil || scoreNotes == nil {
//                 result = scoreCtr
//                 break
//             }
             if compareNotes.count == 0 || scoreNotes.count == 0 {
                 result = scoreCtr
                 break
             }

             if scoreCtr == scoreTimeSlices.count - 1 {
                 if scoreNotes[0].getValue() > compareNotes[0].getValue() {
                     result = scoreCtr
                     break
                 }
                 else {
                     compareNotes[0].setValue(value: scoreNotes[0].getValue())
                 }
             }
             else {
                 if scoreNotes[0].getValue() != compareNotes[0].getValue() {
                     result = scoreCtr
                     break
                 }
             }
             scoreCtr += 1
         }
         return result
     }
    
    //Return the first timeslice index of where the scores differ
//    func getFirstDifferentTimeSliceNew(compareScore:Score) -> Int? {
//        //let compareEntries = compareScore.scoreEntries
//        var result:Int? = nil
//        var scoreCtr = 0
//
//        let scoreTimeSlices = self.getAllTimeSlices()
//        let compareTimeSlices = compareScore.getAllTimeSlices()
//
//        //Adjust score values to include rests since tapping cannot record rests
//        //Rests for the rhythm comparison here have to lengthen the score entry values
//        var scoreValues:[Double] = []
//        var currentNoteValue = 0.0
//        var lastNote:TimeSliceEntry? = nil
//
//        for scoreTimeSlice in scoreTimeSlices {
//            if scoreTimeSlice.entries.count == 0 {
//                continue
//            }
//            let entry = scoreTimeSlice.entries[0]
//            if entry is Note {
//                if let lastNote = lastNote {
//                    scoreValues.append(currentNoteValue)
//                    currentNoteValue = 0
//                }
//                currentNoteValue += entry.getValue()
//                lastNote = entry
//                continue
//            }
//            if entry is Rest {
//                currentNoteValue += entry.getValue()
//                continue
//            }
//        }
//        if let lastNote = lastNote {
//            scoreValues.append(currentNoteValue)
//        }
//
//        //compare values score vs. recorded
//        for scoreValue in scoreValues {
//
//            if compareTimeSlices.count <= scoreCtr {
//                result = scoreCtr
//                break
//            }
//
//            let compareEntry = compareTimeSlices[scoreCtr]
//            let compareEntries = compareEntry.getTimeSlices()
//            //let scoreEntries = scoreTimeSlice.getTimeSlices()
//
//            if compareEntries == nil {
//                result = scoreCtr
//                break
//            }
//            if compareEntries.count == 0 { //} || scoreEntries.count == 0 {
//                result = scoreCtr
//                break
//            }
//
//            if scoreCtr == scoreValues.count - 1 {
//                if scoreValue > compareEntries[0].getValue() {
//                    result = scoreCtr
//                    break
//                }
//                else {
//                    compareEntries[0].setValue(value: scoreValue)
//                }
//            }
//            else {
//                if scoreValue != compareEntries[0].getValue() {
//                    result = scoreCtr
//                    break
//                }
//            }
//            scoreCtr += 1
//        }
//        return result
//    }
    
    func setHiddenStaff(num:Int, isHidden:Bool) {
        DispatchQueue.main.async {
            if self.staffs.count > num {
                //self.hiddenStaffNo = num
                self.staffs[num].isHidden = isHidden
                for staff in self.staffs {
                    staff.update()
                }
            }
        }
    }
    
    func setStudentFeedback(studentFeedack:StudentFeedback? = nil) {
        DispatchQueue.main.async {
            self.studentFeedback = studentFeedack
        }
    }

    func getLastTimeSlice() -> TimeSlice? {
        var ts:TimeSlice?
        for index in stride(from: scoreEntries.count - 1, through: 0, by: -1) {
            let element = scoreEntries[index]
            if element is TimeSlice {
                ts = element as? TimeSlice
                break
            }
        }
        return ts
    }

    func setShowFootnotes(_ on:Bool) {
        DispatchQueue.main.async {
            self.showFootnotes = on
        }
    }
        
    func updateStaffs() {
        for staff in staffs {
            staff.update()
        }
    }
    
    func setStaff(num:Int, staff:Staff) {
        if self.staffs.count <= num {
            self.staffs.append(staff)
        }
        else {
            self.staffs[num] = staff
        }
    }
    
    func getStaff() -> [Staff] {
        return self.staffs
    }
    
//    func keyDesc() -> String {
//        var desc = key.description()
//        if key.type == Key.KeyType.minor {
//            desc += minorScaleType == Scale.MinorType.natural ? " (Natural)" : " (Harmonic)"
//        }
//        return desc
//    }
    
    func setKey(key:Key) {
        //self.key = key
        DispatchQueue.main.async {
            self.key = key
            self.updateStaffs()
        }        
    }
    
    func addTimeSlice() -> TimeSlice {
        let ts = TimeSlice(score: self)
        ts.sequence = self.scoreEntries.count
        self.scoreEntries.append(ts)
        return ts
    }
    
    func addBarLine() {
        let barLine = BarLine()
        barLine.sequence = self.scoreEntries.count
        self.scoreEntries.append(barLine)
    }
    
//    func addRest(rest: Rest) {
//        self.scoreEntries.append(rest)
//    }

    func clear() {
        self.scoreEntries = []
        for staff in staffs  {
            staff.clear()
        }
    }
    
    ///Determine if the stem for the note(s) should go up or down
    func getStemDirection(staff:Staff, notes:[Note]) -> StemDirection {
        var totalOffsets = 0
        for n in notes {
            if n.staffNum == staff.staffNum {
                let placement = staff.getNoteViewPlacement(note: n)
                totalOffsets += placement.offsetFromStaffMidline
            }
        }
        //return Array(repeating: totalOffsets < 0 ? StemDirection.up : StemDirection.down, count: notes.count)
        return totalOffsets <= 0 ? StemDirection.up: StemDirection.down
    }
    
    ///If the last note added was a quaver, identify any previous adjoining quavers and set them to be joined with a quaver bar
    ///Set the beginning, middle and end quavers for the beam
    func addStemCharaceteristics() {
        let lastNoteIndex = self.scoreEntries.count - 1
        let scoreEntry = self.scoreEntries[lastNoteIndex]

        guard scoreEntry is TimeSlice else {
            return
        }

        let timeSlice = scoreEntry as! TimeSlice
        let notes = timeSlice.getTimeSliceNotes()
        if notes.count == 0 {
            return
        }
//        if notes[0].getValue() < 1 {
//            print ("+++++")
//        }
        let lastNote = notes[0]
        lastNote.sequence = self.getAllTimeSlices().count

        //The number of staff lines for a full stem length
        let stemLengthLines = 3.5

        let staff = self.staffs[lastNote.staffNum]
        if lastNote.getValue() != Note.VALUE_QUAVER {
            let stemDirection = getStemDirection(staff: staff, notes: notes)
            for note in notes {
                note.stemDirection = stemDirection
                note.stemLength = stemLengthLines
            }
            return
        }

        //apply the quaver beam back from the last note
        //let endQuaver = notes[0]
        var notesUnderBeam:[Note] = []
        notesUnderBeam.append(lastNote)
        
        ///Figure out the start, middle and end of this group of quavers
        for i in stride(from: lastNoteIndex - 1, through: 0, by: -1) {
            let scoreEntry = self.scoreEntries[i]
            if !(scoreEntry is TimeSlice) {
                break
            }
            let timeSlice = scoreEntry as! TimeSlice
            let notes = timeSlice.getTimeSliceNotes()
            if notes.count > 0 {
                if notes[0].getValue() == Note.VALUE_QUAVER {
                    let note = notes[0]
                    notesUnderBeam.append(note)
                }
                else {
                    break
                }
            }
        }
        
        //Determine if the haver group has up or down stems based on the overall staff placement of the group
        var totalOffset = 0
        for note in notesUnderBeam {
            let placement = staff.getNoteViewPlacement(note: note)
            totalOffset += placement.offsetFromStaffMidline
        }
        
        ///Set each note's beam type and calculate the nett above r below the staff line for the quaver group (for the subsequnet stem up or down decison)
        let startNote = notesUnderBeam[0]
        let startPlacement = staff.getNoteViewPlacement(note: startNote)

        let endNote = notesUnderBeam[notesUnderBeam.count - 1]
        let endPlacement = staff.getNoteViewPlacement(note: endNote)
//        if startNote.midiNumber == 70 {
//            print(endNote.sequence, endNote.midiNumber, endPlacement.offsetFromStaffMidline)
//            print(startNote.sequence, startNote.midiNumber, startPlacement.offsetFromStaffMidline)
//        }
        var beamSlope:Double = Double(endPlacement.offsetFromStaffMidline - startPlacement.offsetFromStaffMidline)
        beamSlope = beamSlope / Double(notesUnderBeam.count - 1)

        var requiredBeamPosition = Double(startPlacement.offsetFromStaffMidline)
        
        for i in 0..<notesUnderBeam.count {
            let note = notesUnderBeam[i]
            if i == 0 {
                note.beamType = .end
                note.stemLength = stemLengthLines
            }
            else {
                if i == notesUnderBeam.count-1 {
                    note.beamType = .start
                    note.stemLength = stemLengthLines
                }
                else {
                    note.beamType = .middle
                    let placement = staff.getNoteViewPlacement(note: note)
                    ///adjust the stem length according to where the note is positioned vs. where the beam slope position requires
                    let stemDiff = Double(placement.offsetFromStaffMidline) - requiredBeamPosition
                    note.stemLength = stemLengthLines + (stemDiff / 2.0 * (totalOffset > 0 ? 1.0 : -1.0))
                }
            }
            requiredBeamPosition += beamSlope
            note.stemDirection = totalOffset > 0 ? .down : .up
        }
    }

    // ================= Student feedback =================
    
    func constuctFeedback(scoreToCompare:Score, timeSliceNumber:Int?, questionTempo:Int,
                          metronomeTempoAtStartRecording:Int, allowTempoVariation:Bool) -> StudentFeedback {
        let feedback = StudentFeedback()
        if let timeSliceNumber = timeSliceNumber {
            let exampleTimeSlices = getAllTimeSlices()
            let exampleTimeSlice = exampleTimeSlices[timeSliceNumber]
            if exampleTimeSlice.getTimeSliceEntries().count > 0 {
                let exampleNote = exampleTimeSlice.getTimeSliceEntries()[0]
                //if let exampleNote = exampleNote {
                let studentTimeSlices = scoreToCompare.getAllTimeSlices()
                if studentTimeSlices.count > timeSliceNumber {
                    let studentTimeSlice = studentTimeSlices[timeSliceNumber]
                    let studentNote = studentTimeSlice.getTimeSliceEntries()[0]
                    //if let studentNote = studentNote {
                    feedback.feedbackExplanation = "The example rhythm was a \(exampleNote.getNoteValueName()). "
                    feedback.feedbackExplanation! += "Your rhythm was a \(studentNote.getNoteValueName())."
                    feedback.indexInError = studentNote.sequence
                    //}
                }
                //}
            }
            feedback.correct = false
        }
        else {
            feedback.correct = true
            feedback.feedbackExplanation = "Good Job!"
            if let recordedTempo = scoreToCompare.recordedTempo {
                let tolerance = Int(Double(metronomeTempoAtStartRecording) * 0.10)
                if !allowTempoVariation && abs(recordedTempo - metronomeTempoAtStartRecording) > tolerance {
                    feedback.feedbackExplanation = "But your tempo of \(recordedTempo) was \(recordedTempo < metronomeTempoAtStartRecording ? "slower" : "faster") than the metronome tempo \(metronomeTempoAtStartRecording) you heard."
                }
            }
        }
        feedback.tempo = recordedTempo
        return feedback
    }
    
    //analyse the student's score against the question score. Markup dfferences. Return false if there are errors
    func markupStudentScore(questionTempo: Int,
                            //recordedTempo:Int,
                            metronomeTempoAtStartRecording: Int,
                            scoreToCompare:Score,
                            allowTempoVariation:Bool) -> Bool {
        var errorsExist = false
        let difference = getFirstDifferentTimeSlice(compareScore: scoreToCompare)
        if let difference = difference {
            if scoreToCompare.scoreEntries.count > 0 {
                let toCompareTimeSlices = scoreToCompare.getAllTimeSlices()
                let toCompareTimeSlice = toCompareTimeSlices[difference < toCompareTimeSlices.count ? difference : toCompareTimeSlices.count - 1]
                if toCompareTimeSlice.getTimeSliceEntries().count > 0 {
                    let mistakeNote = toCompareTimeSlice.getTimeSliceEntries()[0]
                    //mistakeNote.noteTag = .inError
                    errorsExist = true
                    //mark the note in the example score to hilight what was expected
                    let timeslices = self.getAllTimeSlices()
                    let timeslice = timeslices[difference]
                    if timeslice.getTimeSliceEntries().count > 0 {
                        //timeslice.getTimeSlices()[0].setNoteTag(.hilightExpected)
                    }
                    scoreToCompare.setStudentFeedback(
                        studentFeedack: self.constuctFeedback(scoreToCompare: scoreToCompare,
                                                              timeSliceNumber:difference,
                                                              questionTempo: questionTempo,
                                                              metronomeTempoAtStartRecording: metronomeTempoAtStartRecording,
                                                              allowTempoVariation: allowTempoVariation))
                }
            }
            //mark the remaining entries after the difference as invisible in display
            let toCompareTimeSlices = scoreToCompare.getAllTimeSlices()
            if difference + 1 < toCompareTimeSlices.count {
                for t in difference+1..<toCompareTimeSlices.count {
                    let toCompareTimeSlice = toCompareTimeSlices[t]
                    //if toCompareTimeSliceEntries.getTimeSliceEntries().count > 0 {
                        //toCompareTimeSliceEntries.getTimeSlices()[0].noteTag = .renderedInError
                    //}
                }
            }
        }
        else {
            scoreToCompare.setStudentFeedback(studentFeedack: self.constuctFeedback(scoreToCompare: scoreToCompare, timeSliceNumber:nil,
                                                                                    questionTempo: questionTempo,
                                                                                    metronomeTempoAtStartRecording: metronomeTempoAtStartRecording,
                                                                                    allowTempoVariation: allowTempoVariation))
        }
        return errorsExist
    }
    
    func clearTaggs() {
        for ts in getAllTimeSlices() {
            for note in ts.getTimeSliceNotes() {
                note.setNoteTag(.noTag)
            }
        }
    }
}
