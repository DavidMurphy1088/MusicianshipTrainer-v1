import Foundation

class TimeSlice : ScoreEntry, ObservableObject {
    @Published var notes:[Note]
    @Published var tagHigh:String?
    @Published var tagLow:String?
    @Published var notesLength:Int?
    
    var score:Score?
    var footnote:String?
    var barLine:Int = 0
    private static var idIndex = 0
    
    init(score:Score?) {
        self.score = score
        self.notes = []
        TimeSlice.idIndex += 1
    }
    
    func addNote(n:Note) {
        self.notes.append(n)
        if let score = self.score {
            score.updateStaffs()
            score.addStemCharaceteristics()
        }
    }
    
    func setTags(high:String, low:String) {
        DispatchQueue.main.async {
            self.tagHigh = high
            self.tagLow = low
        }
    }
    
    func addChord(c:Chord) {
        for n in c.getNotes() {
            self.notes.append(n)
        }
        if let score = score {
            score.updateStaffs()
        }
    }
    
    static func == (lhs: TimeSlice, rhs: TimeSlice) -> Bool {
        return lhs.id == rhs.id
    }
        
    func addTonicChord() {
        guard let score = score else {
            return
        }
        if getNotes()?.count == 0 {
            return
        }
        let lastNote = getNotes()![0]
        let isDotted = lastNote.isDotted
        
        if score.key.keySig.accidentalCount > 0 { //G Major
            addNote(n: Note(num: Note.MIDDLE_C - 5 - 12, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
            addNote(n: Note(num: Note.MIDDLE_C - 1 - 12, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
            addNote(n: Note(num: Note.MIDDLE_C + 2 - 12, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
        }
        else {
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE + 4, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
            addNote(n: Note(num: Note.MIDDLE_C - Note.OCTAVE + 7, value: lastNote.getValue(), staffNum:1, isDotted: isDotted))
        }

    }
}
