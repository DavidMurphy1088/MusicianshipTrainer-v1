import Foundation

class TimeSlice : ScoreEntry {
    @Published var entries:[TimeSliceEntry]
    @Published var tagHigh:String?
    @Published var tagLow:String?
    @Published var notesLength:Int?
    @Published var statusTag:StatusTag = .noTag

    var score:Score?
    var footnote:String?
    var barLine:Int = 0
    private static var idIndex = 0
    var beatNumber:Double = 0.0 //the beat in the bar that the timeslice is at

    init(score:Score?) {
        self.score = score
        self.entries = []
        TimeSlice.idIndex += 1
    }
    
    func setStatusTag(_ tag: StatusTag) {
        DispatchQueue.main.async {
            self.statusTag = tag
        }
    }

    func getValue() -> Double {
        if entries.count > 0 {
            return entries[0].getValue()
        }
        return 0
    }
    
    func addNote(n:Note) {
        self.entries.append(n)
        n.timeSlice = self
        if let score = score {
            score.updateStaffs()
            score.addBeamAndStemCharaceteristics()
        }
    }
    
    func addRest(rest:Rest) {
        self.entries.append(rest)
        if let score = score {
            score.updateStaffs()
            score.addBeamAndStemCharaceteristics()
        }
    }

    func addChord(c:Chord) {
        for n in c.getNotes() {
            self.entries.append(n)
        }
        if let score = score {
            score.addBeamAndStemCharaceteristics()
            score.updateStaffs()
        }
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
        
    func addTriadAt(timeSlice:TimeSlice, rootNoteMidi:Int, value: Double, staffNum:Int) {
        if getTimeSliceEntries().count == 0 {
            return
        }
        if let score = score {
            let triad = score.key.makeTriadAt(timeSlice:timeSlice, rootMidi: rootNoteMidi, value: value, staffNum: staffNum)
            for note in triad {
                addNote(n: note)
            }
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
