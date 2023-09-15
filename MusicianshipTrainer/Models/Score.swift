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


class StudentFeedback : ObservableObject {
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
    
    func getDurationToFirstError() -> Double {
        var duration = 0.0
        for timeSlice in self.getAllTimeSlices() {
            if timeSlice.entries.count > 0 {
                let entry = timeSlice.entries[0]
                if entry.statusTag == .inError {
                    break
                }
                else {
                    duration += entry.getValue()
                }
            }
        }
        return duration
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
            if timeSlice.entries.count > 0 {
                if let rest = timeSlice.entries[0] as? Rest {
                    break
                }
            }
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
        
        //Determine if the quaver group has up or down stems based on the overall staff placement of the group
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
    
    func copyEntries(from:Score) {
        self.scoreEntries = from.scoreEntries
    }
    
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
    
    func errorCount() -> Int {
        var cnt = 0
        for timeSlice in self.getAllTimeSlices() {
            let entries = timeSlice.getTimeSliceEntries()
            if entries.count > 0 {
                if entries[0].statusTag == .inError {
                    cnt += 1
                }
            }
        }
        return cnt
    }
    
    ///Compare this score to an input tapped score.
    ///Look for notes in the question score that did have a tap at their time offset and flag them.
    ///Flag taps that are not associated with notes - extraneous taps
    
    func flagNotesMissingRequiredTap(tappingScore:Score) {
        let questionTimeSlices = self.getAllTimeSlices()
        let tappedTimeSlices = tappingScore.getAllTimeSlices()
        var runningQuestionTime = 0.0
        
        //var tapScoreWasFlagged = false
        var questionScoreWasFlagged = false

        for timeSlice in tappingScore.getAllTimeSlices() {
            timeSlice.entries[0].statusTag = .inError
        }
        
        ///Check every question entry note has a tap at the same time location
        for questionSlice in questionTimeSlices {
            var questionNote:TimeSliceEntry? = nil
            if questionSlice.entries.count > 0 {
                let questionEntry = questionSlice.entries[0]
                questionNote = questionEntry as? Note
                if questionNote == nil {
                    ///Dont check that a rest has an associated tapped value
                    runningQuestionTime += questionEntry.getValue()
                    continue
                }
            }
            else {
                continue
            }
            
            var tapLocation = 0.0
            var tappedFound = false
            for tappedTimeSlice in tappedTimeSlices {
                if tapLocation == runningQuestionTime {
                    tappedFound = true
                    tappedTimeSlice.entries[0].statusTag = .noTag
                    break
                }
                else {
                    if tapLocation > runningQuestionTime {
                        break
                    }
                }
                if tappedTimeSlice.entries.count > 0 {
                    tapLocation += tappedTimeSlice.entries[0].getValue()
                }
            }
                        
            if !tappedFound {
                if !questionScoreWasFlagged {
                    questionNote!.statusTag = .inError
                    questionScoreWasFlagged = true
                }
            }
            runningQuestionTime += questionNote!.getValue()
        }
    }
    
    ///A tapped score does not contain rests or bar lines so try to add them as they appear in the question score
    ///Represent a single tap as its components from the question score. e.g. a tap of 2 might be represented as a note of 1 and then a rest of 1
    ///Once a tapped value is incorrect vs. the question score, just copy in the rest of the student's rhythm
    ///The output score should agree exactly with the question score up until the point of error in tap value
    func fitScoreToQuestionScore(tappedScore:Score) -> Score {
        let outputScore = Score(timeSignature: self.timeSignature, linesPerStaff: 1, noteSize: self.noteSize)
        let staff = Staff(score: outputScore, type: .treble, staffNum: 0, linesInStaff: 1)
        outputScore.setStaff(num: 0, staff: staff)
        
        var questionIndex = 0
        let tappedTimeSlices = tappedScore.getAllTimeSlices()
        let questionTimeSlices = self.getAllTimeSlices()
        var barDuration = 0.0
        var inSync = true
        print("+++++++++++++++")
        for ts in tappedTimeSlices {
            print("========> tapped  ", ts.entries[0].getValue(), ts.entries[0].statusTag)
        }
        for ts in questionTimeSlices {
            print("========> question", ts.entries[0].getValue(), ts.entries[0].statusTag)
        }
        var tapInErrorWasFlagged = false

        for tappedIndex in 0..<tappedTimeSlices.count {
            let tappedTimeSlice = tappedTimeSlices[tappedIndex]
            let tap = tappedTimeSlice.entries[0]
            let tappedValue = tap.getValue()
            print("---", tappedValue, tap.statusTag, inSync, barDuration, questionIndex, questionIndex)

            var questionValue = 0.0
            if tap.statusTag == .inError {
                inSync = false
            }
            
            if inSync {
                while questionValue < tappedValue && questionIndex < questionTimeSlices.count {
                    let ts = outputScore.addTimeSlice()
                    if let questionNote = questionTimeSlices[questionIndex].entries[0] as? Note {
                        if questionNote.statusTag == .inError {
                            inSync = false
                            break
                        }
                        else {
                            let noteValue = questionNote.getValue()
                            questionValue += noteValue
                            if questionValue <= tappedValue {
                                ts.addNote(n: Note(note: questionNote))
                                barDuration += questionValue
                            }
                        }
                    }
                    if let questionRest = questionTimeSlices[questionIndex].entries[0] as? Rest {
                        let restValue = questionRest.getValue()
                        questionValue += restValue
                        if questionValue <= tappedValue {
                            ts.addRest(rest: questionRest)
                            barDuration += restValue
                        }
                    }
                    questionIndex += 1
                }
            }
            else {
                let tappedNote = Note(note: tap as! Note)
                if !tapInErrorWasFlagged {
                    let qq = getDurationToFirstError()
                    let tt = tappedScore.getDurationToFirstError()
                    print("  ERR---", tappedValue, tap.statusTag, inSync, barDuration, questionIndex, questionIndex, "...", qq, tt)
                    if qq > tt {
                        if tappedIndex > 0 {
                            let lastSlice = tappedTimeSlices[tappedIndex-1]
                            if lastSlice.entries.count > 0 {
                                if let lastTap = lastSlice.entries[0] as? Note {
                                    let ts = outputScore.addTimeSlice()
                                    ts.addNote(n: Note(note: lastTap))
                                }
                            }
                        }
                    }
                    tappedNote.statusTag = .inError
                    tapInErrorWasFlagged = true
                }
                else {
                    tappedNote.statusTag = .afterError
                }
                let ts = outputScore.addTimeSlice()
                ts.addNote(n: tappedNote)
                barDuration += tap.getValue()
            }
            if barDuration >= Double(self.timeSignature.top) {
                if inSync {
                    outputScore.addBarLine()
                }
                barDuration = 0
            }
        }
        return outputScore
    }
    
    func clearTaggs() {
        for ts in getAllTimeSlices() {
            for note in ts.getTimeSliceNotes() {
                note.setStatusTag(.noTag)
            }
        }
    }
}
