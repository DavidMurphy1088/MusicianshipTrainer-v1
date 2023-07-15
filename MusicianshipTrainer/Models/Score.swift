import Foundation
import AVKit
import AVFoundation

class ScoreEntry : Hashable {
    let id = UUID()
    var sequence:Int = 0
    static func == (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func getNotes() -> [Note]? {
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            return ts.notes
        }
        return nil
    }
}

class BarLine : ScoreEntry {
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
            print("ScoreView::staffHeight", height)
            StaffLayoutSize.lastHeight = height
        }
        return height
    }

}

class Score : ObservableObject {
    let id = UUID()
    var timeSignature:TimeSignature
    let ledgerLineCount =  2 //3//4 is required to represent low E
    
    @Published var key:Key = Key(type: Key.KeyType.major, keySig: KeySignature(type: AccidentalType.sharp, count: 0))
    @Published var showNotes = true
    @Published var showFootnotes = false
    @Published var studentFeedback:StudentFeedback? = nil
    
    var staffs:[Staff] = []
    
    var minorScaleType = Scale.MinorType.natural
    var recordedTempo:Int?
    static let maxTempo:Float = 200
    static let minTempo:Float = 30
    static let midTempo:Float = Score.minTempo + (Score.maxTempo - Score.minTempo) / 2.0
    static let slowTempo:Float = Score.minTempo + (Score.maxTempo - Score.minTempo) / 4.0
    
    private var totalStaffLineCount:Int = 0
    static var accSharp = "\u{266f}"
    static var accNatural = "\u{266e}"
    static var accFlat = "\u{266d}"
    var scoreEntries:[ScoreEntry] = []
    var label:String? = nil
    
    init(timeSignature:TimeSignature, linesPerStaff:Int) {
        self.timeSignature = timeSignature
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
        //let compareEntries = compareScore.scoreEntries
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
            let compareNotes = compareEntry.getNotes()
            let scoreNotes = scoreTimeSlice.getNotes()

            if compareNotes == nil || scoreNotes == nil {
                result = scoreCtr
                break
            }
            if compareNotes?.count == 0 || scoreNotes!.count == 0 {
                result = scoreCtr
                break
            }

            if scoreCtr == scoreTimeSlices.count - 1 {
                if scoreNotes![0].getValue() > compareNotes![0].getValue() {
                    result = scoreCtr
                    break
                }
                else {
                    compareNotes![0].setValue(value: scoreNotes![0].getValue())
                }
            }
            else {
                if scoreNotes![0].getValue() != compareNotes![0].getValue() {
                    result = scoreCtr
                    break
                }
            }
            scoreCtr += 1
        }
        return result
    }
    
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
    
    func keyDesc() -> String {
        var desc = key.description()
        if key.type == Key.KeyType.minor {
            desc += minorScaleType == Scale.MinorType.natural ? " (Natural)" : " (Harmonic)"
        }
        return desc
    }
    
    func setKey(key:Key) {
        self.key = key
        DispatchQueue.main.async {
            self.key = key
        }
        updateStaffs()
    }

//    func setTempo(temp: Int, pitch: Int? = nil) {
//        self.tempo = Float(temp)
//    }
    
    func addTimeSlice() -> TimeSlice {
        let ts = TimeSlice(score: self)
        ts.sequence = self.scoreEntries.count
        self.scoreEntries.append(ts)
        return ts
    }
    
    func addBarLine() { //atScoreEnd:Bool? = false) {
        let barLine = BarLine()
        barLine.sequence = self.scoreEntries.count
        self.scoreEntries.append(barLine)
    }

    func clear() {
        self.scoreEntries = []
        for staff in staffs  {
            staff.clear()
        }
    }

    func addStemCharaceteristics() {
        var ctr = 0
        var underBeam = false
        var previousNote:Note? = nil
        let timeSlices = self.getAllTimeSlices()
        for timeSlice in timeSlices {
            if timeSlice.notes.count == 0 {
                continue
            }
            let note = timeSlice.notes[0]
            note.beamType = .none
            note.sequence = ctr
            if note.getValue() == Note.VALUE_QUAVER {
                if !underBeam {
                    note.beamType = .start
                    underBeam = true
                }
                else {
                    note.beamType = .middle
                }
            }
            else {
                if underBeam {
                    if let beamEndNote = previousNote {
                        if beamEndNote.getValue() == Note.VALUE_QUAVER {
                            beamEndNote.beamType = .end
                        }
                        //update the notes under the quaver beam with the end note of the beam
                        var idx = ctr - 1
                        while idx >= 0 {
                            let prevNote = timeSlices[idx].notes[0]
                            if prevNote.getValue() != Note.VALUE_QUAVER {
                                break
                            }
                            prevNote.beamEndNote = beamEndNote
                            idx = idx - 1
                        }
                    }
                    underBeam = false
                }
            }
            previousNote = note
            ctr += 1
        }
        
    }
        
    // ================= Student feedback =================
    
    func constuctFeedback(scoreToCompare:Score, timeSliceNumber:Int?, tempo:Int, allowTempoVariation:Bool) -> StudentFeedback {
        let feedback = StudentFeedback()
        if let timeSliceNumber = timeSliceNumber {
            let exampleTimeSlices = getAllTimeSlices()
            let exampleTimeSlice = exampleTimeSlices[timeSliceNumber]
            let exampleNote = exampleTimeSlice.getNotes()?[0]
            if let exampleNote = exampleNote {
                let studentTimeSlices = scoreToCompare.getAllTimeSlices()
                if studentTimeSlices.count > timeSliceNumber {
                    let studentTimeSlice = studentTimeSlices[timeSliceNumber]
                    let studentNote = studentTimeSlice.getNotes()?[0]
                    if let studentNote = studentNote {
                        feedback.feedbackExplanation = "The example rhythm was a \(exampleNote.getNoteValueName()). "
                        feedback.feedbackExplanation! += "Your rhythm was a \(studentNote.getNoteValueName())."
                        feedback.indexInError = studentNote.sequence
                    }
                }
            }
            feedback.correct = false
        }
        else {
            feedback.correct = true
            feedback.feedbackExplanation = "Good Job!"
            if let recordedTempo = scoreToCompare.recordedTempo {
                if !allowTempoVariation && abs(recordedTempo - tempo) > 10 {
                    feedback.feedbackExplanation = "But your tempo was \(recordedTempo < tempo ? "slower" : "faster") than the question tempo."
                }
            }
        }
        feedback.tempo = tempo
        return feedback
    }
    
    //analyse the student's score against this score. Markup dfferences. Return false if there are errors
    func markupStudentScore(questionTempo: Int, scoreToCompare:Score, allowTempoVariation:Bool) -> Bool {
        var errorsExist = false
        let difference = getFirstDifferentTimeSlice(compareScore: scoreToCompare)
        if let difference = difference {
            if scoreToCompare.scoreEntries.count > 0 {
                let toCompareTimeSlices = scoreToCompare.getAllTimeSlices()
                let toCompareTimeSlice = toCompareTimeSlices[difference < toCompareTimeSlices.count ? difference : toCompareTimeSlices.count - 1]
                if toCompareTimeSlice.notes.count > 0 {
                    let mistakeNote = toCompareTimeSlice.notes[0]
                    mistakeNote.noteTag = .inError
                    errorsExist = true
                    //mark the note in the example score to hilight what was expected
                    let timeslices = self.getAllTimeSlices()
                    let timeslice = timeslices[difference]
                    if timeslice.notes.count > 0 {
                        timeslice.notes[0].setNoteTag(.hilightExpected)
                    }
                    scoreToCompare.setStudentFeedback(studentFeedack: self.constuctFeedback(scoreToCompare: scoreToCompare, timeSliceNumber:difference, tempo: questionTempo, allowTempoVariation: allowTempoVariation))
                }
            }
            //mark the remaining entries after the difference as invisibile in display
            let toCompareTimeSlices = scoreToCompare.getAllTimeSlices()
            if difference + 1 < toCompareTimeSlices.count {
                for t in difference+1..<toCompareTimeSlices.count {
                    let toCompareTimeSlice = toCompareTimeSlices[t]
                    if toCompareTimeSlice.notes.count > 0 {
                        toCompareTimeSlice.notes[0].noteTag = .renderedInError
                    }
                }
            }
        }
        else {
            scoreToCompare.setStudentFeedback(studentFeedack: self.constuctFeedback(scoreToCompare: scoreToCompare, timeSliceNumber:nil, tempo: questionTempo, allowTempoVariation: allowTempoVariation))
        }
        return errorsExist
    }
    
    func clearTaggs() {
        for ts in getAllTimeSlices() {
            for note in ts.notes {
                note.setNoteTag(.noTag)
            }
        }
    }
}
