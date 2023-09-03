import Foundation

class TimeSlice : ScoreEntry {
    @Published var entries:[TimeSliceEntry]
    @Published var tagHigh:String?
    @Published var tagLow:String?
    @Published var notesLength:Int?
    var score:Score

    var footnote:String?
    var barLine:Int = 0
    private static var idIndex = 0
    
    init(score:Score) {
        self.score = score
        self.entries = []
        TimeSlice.idIndex += 1
    }
    
    func addNote(n:Note) {
        self.entries.append(n)
        score.updateStaffs()
        score.addStemCharaceteristics()
    }
    
    func addRest(rest:Rest) {
        self.entries.append(rest)
        score.updateStaffs()
        score.addStemCharaceteristics()
    }

    func setTags(high:String, low:String) {
        DispatchQueue.main.async {
            self.tagHigh = high
            self.tagLow = low
        }
    }
    
    func addChord(c:Chord) {
        for n in c.getNotes() {
            self.entries.append(n)
        }
        score.updateStaffs()
    }
    
    static func == (lhs: TimeSlice, rhs: TimeSlice) -> Bool {
        return lhs.id == rhs.id
    }
        
    func addTonicChord() {
        if getTimeSliceEntries().count == 0 {
            return
        }
        let lastNote = getTimeSliceEntries()[0]
        
        if score.key.keySig.accidentalCount == 2 { //D Major
            addNote(n: Note(num: Note.MIDDLE_C + 2 - 12, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C + 6 - 12, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C + 9 - 12, value: lastNote.getValue(), staffNum:1))
        }
        if score.key.keySig.accidentalCount == 1 { //G Major
            addNote(n: Note(num: Note.MIDDLE_C - 5 - 12, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C - 1 - 12, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C + 2 - 12, value: lastNote.getValue(), staffNum:1))
        }
        if score.key.keySig.accidentalCount == 0 {
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE + 4, value: lastNote.getValue(), staffNum:1))
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE + 7, value: lastNote.getValue(), staffNum:1))
        }
    }
    
    func anyNotesRotated() -> Bool {
        for n in entries {
            if n is Note {
                let note:Note = n as! Note
                if note.rotated {
                    return true
                }
            }
        }
        return false
    }
}
