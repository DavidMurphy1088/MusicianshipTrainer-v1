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
        //score.addStemCharaceteristics()
    }

    func addChord(c:Chord) {
        for n in c.getNotes() {
            self.entries.append(n)
        }
        score.addStemCharaceteristics()
        score.updateStaffs()
    }
    
    func setTags(high:String, low:String) {
        DispatchQueue.main.async {
            self.tagHigh = high
            self.tagLow = low
        }
    }
    
    static func == (lhs: TimeSlice, rhs: TimeSlice) -> Bool {
        return lhs.id == rhs.id
    }
        
    func addTonicChord() {
        if getTimeSliceEntries().count == 0 {
            return
        }
        let lastNote = getTimeSliceEntries()[0]
        let triad = score.key.makeTriad(value: lastNote.getValue(), staffNum: 1)
        for note in triad {
            addNote(n: note)
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
