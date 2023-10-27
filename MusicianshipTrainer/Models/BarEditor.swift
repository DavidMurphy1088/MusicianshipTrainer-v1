
import Foundation

class BarEditor: ObservableObject {
    let contentSection:ContentSection
    let score:Score
    var notifyFunction: ((_ score:Score)->Void)?
    
    @Published var states:[Bool] = []

    enum BarModifyType {
        case delete
        case beat
        case silent
        case original
    }
    
    init (contentSection:ContentSection, score:Score) {
        self.contentSection = contentSection
        self.score = score
        self.states = Array(repeating: false, count: score.getBarCount())
    }
    
//    func log() -> Bool {
//        print ("\n========== Bar Manager")
//        for i in 0..<states.count {
//            print("State", i, states[i])
//        }
//        return true
//    }
    
    func toggleState(_ i:Int) {
        DispatchQueue.main.async { [self] in
            if !states[i] {
                for s in 0..<self.states.count {
                    states[s] = false
                }
            }
            states[i].toggle()
        }
    }
    ///Modify the target bar number in the input score according the way specified
    ///Leave all the rest of the inut score unmodiifed
    func reWriteBar(targetBar: Int, way: BarModifyType) {
        guard let notifyFunction = notifyFunction else {
            return
        }
        let newScore =  Score(key: Key(type: .major, keySig: KeySignature(type: .sharp, keyName: "")),
                              timeSignature: TimeSignature(top: score.timeSignature.top, bottom: score.timeSignature.bottom),
                              linesPerStaff: 5)
        let staff = Staff(score: newScore, type: .treble, staffNum: 0, linesInStaff: 1)
        newScore.setStaff(num: 0, staff: staff)

        var barNum = 0
        var barWasModified = false
        var deleteNextBarLine = false

        for entry in score.scoreEntries {
            if entry is BarLine {
                barNum += 1
                if deleteNextBarLine {
                    deleteNextBarLine = false
                }
                else {
                    if barNum != targetBar {
                        newScore.addBarLine()
                    }
                }
                continue
            }

            guard let fromTimeSlice = entry as? TimeSlice else {
                continue
            }
            if fromTimeSlice.entries.count == 0 {
                continue
            }
            
            let fromEntry = fromTimeSlice.entries[0]
            
            if barNum == targetBar {

                ///Modify the target bar according to the specified way
                if barWasModified {
                    continue
                }
                else {
                    if way == .delete {
                        deleteNextBarLine = (targetBar == 0 && barNum == 0)
                    }
                    if way == .beat {
                        for _ in 0..<newScore.timeSignature.top {
                            let newTimeSlice = newScore.createTimeSlice()
                            let newNote = Note(timeSlice: newTimeSlice, num: 71, value:1.0, staffNum: 0)
                            newNote.isOnlyRhythmNote = true
                            newTimeSlice.addNote(n: newNote)
                        }
                    }
                    if way == .silent {
                        if newScore.timeSignature.top == 3 {
                            var newTimeSlice = newScore.createTimeSlice()
                            newTimeSlice.addRest(rest: Rest(timeSlice: newTimeSlice, value: 2.0, staffNum: 0))
                            newTimeSlice = newScore.createTimeSlice()
                            newTimeSlice.addRest(rest: Rest(timeSlice: newTimeSlice, value: 1.0, staffNum: 0))
                        }
                        else {
                            let newTimeSlice = newScore.createTimeSlice()
                            newTimeSlice.addRest(rest: Rest(timeSlice: newTimeSlice, value: Double(newScore.timeSignature.top), staffNum: 0))
                        }
                    }
                    if way == .original {
                        //let timeSlices = score.getTimeSlicesForBar(bar: targetBar)
                        let timeSlices = contentSection.parseData(staffCount: score.staffs.count, onlyRhythm: true).getTimeSlicesForBar(bar: targetBar)
                        for timeSlice in timeSlices {
                            let newTimeSlice = newScore.createTimeSlice()
                            for timeSliceEntry in timeSlice.getTimeSliceEntries() {
                                if timeSliceEntry is Rest {
                                    let rest = Rest(timeSlice: timeSlice, value: timeSliceEntry.getValue(), staffNum: timeSliceEntry.staffNum)
                                    newTimeSlice.addRest(rest: rest)
                                }
                                if timeSliceEntry is Note {
                                    let note = timeSliceEntry as! Note
                                    let newNote = Note(timeSlice: newTimeSlice, num: note.midiNumber, value: note.getValue(), staffNum: timeSliceEntry.staffNum)
                                    newNote.isOnlyRhythmNote = note.isOnlyRhythmNote
                                    newTimeSlice.addNote(n: newNote)
                                }
                            }
                        }
                    }
                    barWasModified = true
                }
            }
            else {
                let newTimeSlice = newScore.createTimeSlice()
                ///Copy the input score verbatim
                if fromEntry is Rest {
                    newTimeSlice.addRest(rest: Rest(timeSlice: newTimeSlice, value: fromEntry.getValue(), staffNum: 0))
                }
                if let fromNote = fromEntry as? Note {
                    let newNote = Note(timeSlice: newTimeSlice, num: fromNote.midiNumber, value:fromNote.getValue(), staffNum: 0)
                    newNote.isOnlyRhythmNote = true
                    newTimeSlice.addNote(n: newNote)
                }
            }
        }
        notifyFunction(newScore)
    }
    
    func hiliteNotesInBar(bar:Int, way:Bool) {
        var currentBarNo = 0
        for entry in score.scoreEntries {
            if currentBarNo == bar {
                if let ts = entry as? TimeSlice {
                    ts.setStatusTag(way ? .hilightAsCorrect : .noTag)
                }
            }
            if entry is BarLine {
                currentBarNo += 1
            }
        }
    }
    
}