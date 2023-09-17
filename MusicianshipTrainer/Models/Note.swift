import Foundation
import SwiftUI

class TimeSliceEntry : ObservableObject, Equatable, Hashable {
    @Published var hilite = false
    @Published var statusTag:StatusTag = .noTag

    let id = UUID()
    var staffNum:Int //Narrow the display of the note to just one staff
    var isDotted:Bool = false
    var sequence:Int = 0 //the note's sequence position

    fileprivate var value:Double = Note.VALUE_QUARTER

    init(value:Double, staffNum: Int) {
        self.value = value
        self.staffNum = staffNum
    }
    
    static func == (lhs: TimeSliceEntry, rhs: TimeSliceEntry) -> Bool {
        //return lhs.midiNumber == rhs.midiNumber
        return lhs.id == rhs.id
    }
    
    func getValue() -> Double {
        return self.value
    }
    
    func setValue(value:Double) {
        self.value = value
        if value == 3.0 {
            self.isDotted = true
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func setHilite(hilite: Bool) {
        DispatchQueue.main.async {
            self.hilite = hilite
        }
    }
    
    func getNoteValueName() -> String {
        var name = self.isDotted ? "dotted " : ""
        switch self.value {
        case 0.50 :
            name += "quaver"
        case 1.0 :
            name += "crotchet"
        case 1.5 :
            name += "dotted crotchet"
        case 2.0 :
            name += "minim"
        case 3.0 :
            name += "minim"
        default :
            name += "semibreve"
        }
        return name
    }

}

class BarLine : ScoreEntry {
}

class Rest : TimeSliceEntry {    
    override init(value:Double, staffNum:Int) {
        super.init(value: value, staffNum: staffNum)
        //self.value = value
    }
    
    init(r:Rest) {
        super.init(value: r.value, staffNum: r.staffNum)
    }
}

enum AccidentalType {
    case sharp
    case flat
}

enum HandType {
    case left
    case right
}

enum QuaverBeamType {
    case none
    case start
    case middle
    case end
}

enum StemDirection {
    case up
    case down
}

enum StatusTag {
    case noTag
    case inError
    case afterError
    case renderedInError //e.g. all rhythm after a rhythm error is moot
    case hilightExpected //hilight the correct note that was expected
}

class NoteStaffPlacement {
    var midi:Int
    var offsetFromStaffMidline:Int
    var accidental: Int?
    
    init(midi:Int, offsetFroMidLine:Int, accidental:Int?=nil) {
        self.midi = midi
        self.offsetFromStaffMidline = offsetFroMidLine
        self.accidental = accidental
    }
}

class Note : TimeSliceEntry, Comparable {
    
    static let MIDDLE_C = 60 //Midi pitch for C4
    static let OCTAVE = 12
    static let noteNames:[Character] = ["A", "B", "C", "D", "E", "F", "G"]
    
    static let VALUE_QUAVER = 0.5
    static let VALUE_QUARTER = 1.0
    static let VALUE_HALF = 2.0
    static let VALUE_WHOLE = 4.0

    var midiNumber:Int
    var isOnlyRhythmNote = false
    var accidental:Int? = nil //< 0 = flat, ==0 natural, > 0 sharp    
    var rotated:Bool = false //true if note must be displayed vertically rotated due to closeness to a neighbor.
    
    var beamType:QuaverBeamType = .none
    var stemDirection:StemDirection = .up
    var stemLength:Double = 0.0
    
    //the note where the quaver beam for this note ends
    var beamEndNote:Note? = nil
    
    static func < (lhs: Note, rhs: Note) -> Bool {
        return lhs.midiNumber < rhs.midiNumber
    }
    
    static func isSameNote(note1:Int, note2:Int) -> Bool {
        return (note1 % 12) == (note2 % 12)
    }
    
    init(num:Int, value:Double = Note.VALUE_QUARTER, staffNum:Int, accidental:Int?=nil) {//}, isDotted:Bool = false) {
        self.midiNumber = num
        super.init(value: value, staffNum: staffNum)

        self.isDotted = [0.75, 1.5, 3.0].contains(value)
        self.accidental = accidental
        if value == 3.0 {
            self.isDotted = true
        }
    }
    
    init(note:Note) {
        self.midiNumber = note.midiNumber
        super.init(value: note.getValue(), staffNum: note.staffNum)
        self.isDotted = note.isDotted
        self.accidental = note.accidental
        self.isOnlyRhythmNote = note.isOnlyRhythmNote
    }

    func setStatusTag(_ tag: StatusTag) {
        DispatchQueue.main.async {
            self.statusTag = tag
        }
    }
    
    func setIsOnlyRhythm(way: Bool) {
        self.isOnlyRhythmNote = way
        if self.isOnlyRhythmNote {
            self.midiNumber = Note.MIDDLE_C + Note.OCTAVE - 1
        }
        
    }

    static func staffNoteName(idx:Int) -> Character {
        if idx >= 0 {
            return self.noteNames[idx % noteNames.count]
        }
        else {
            return self.noteNames[noteNames.count - (abs(idx) % noteNames.count)]
        }
    }

    static func getAllOctaves(note:Int) -> [Int] {
        var notes:[Int] = []
        for n in 0...88 {
            if note >= n {
                if (note - n) % 12 == 0 {
                    notes.append(n)
                }
            }
            else {
                if (n - note) % 12 == 0 {
                    notes.append(n)
                }
            }
        }
        return notes
    }
    
    static func getClosestOctave(note:Int, toPitch:Int, onlyHigher: Bool = false) -> Int {
        let pitches = Note.getAllOctaves(note: note)
        var closest:Int = note
        var minDist:Int?
        for p in pitches {
            if onlyHigher {
                if p < toPitch {
                    continue
                }
            }
            let dist = abs(p - toPitch)
            if minDist == nil || dist < minDist! {
                minDist = dist
                closest = p
            }
        }
        return closest
    }
    
    ///Find the first note for this quaver group
    func getBeamStartNote(score:Score, np: NoteLayoutPositions) -> Note {
//        if self.midiNumber == 72 {
//            print("X")
//        }

        let endNote = self
        if endNote.beamType != .end {
            return endNote
        }
        var result:Note? = nil
        var idx = score.scoreEntries.count - 1
        var foundEndNote = false
        while idx>=0 {
            let ts = score.scoreEntries[idx]
            if ts is TimeSlice {
                let notes = ts.getTimeSliceNotes()
                if notes.count > 0 {
                    let note = notes[0]
                    if note.sequence == endNote.sequence {
                        foundEndNote = true
                    }
                    else {
                        if foundEndNote {
                            if note.beamType == .start {
                                result = note
                                break
                            }
                            else {
                                if note.getValue() != Note.VALUE_QUAVER {
                                    break
                                }
                            }
                        }
                    }
                }
            }
            if ts is BarLine {
                if foundEndNote {
                    break
                }
            }

            idx = idx - 1
        }
        if result == nil {
            return endNote
        }
        else {
            return result!
        }
    }
    
    //cause notes that are set for specifc staff to be tranparent on other staffs
    func getColor(staff:Staff) -> Color {
        if statusTag == .inError {
            return Color(.red)
        }
        if statusTag == .afterError {
            return Color(.lightGray)
        }
        if statusTag == .renderedInError {
            return Color(.clear)
        }
        if statusTag == .hilightExpected {
            return Color(red: 0, green: 0.5, blue: 0)
        }
//        if let accidental = accidental {
//            return Color.blue
//        }

        if staffNum == nil {
            return Color(.black)
        }
        return Color(staffNum == staff.staffNum ? .black : .clear)
    }
    
    ///The note has a default accidental determined by which key the score is in but can be overidden by content specifying a written accidental
    ///The written accidental must overide the default accidental and the note's offset adjusted accordingly.
    ///When a written accidental is specified this code checks the note offset positions for this staff (coming from the score's key) and decides how the note should move from its
    ///default staff offset based on the written accidental. e.g. a note at MIDI 75 would be defaulted to show as E ♭ in C major but may be speciifed to show as D# by a written
    ///accidentail. In that case the note must shift down 1 unit of offset.
    ///
    func getNoteDisplayCharacteristics(staff:Staff) -> NoteStaffPlacement {
//        if self.midiNumber == 60 {
//            print("X")
//        }

        let defaultNoteData = staff.getNoteViewPlacement(note: self)
        var offsetFromMiddle = defaultNoteData.offsetFromStaffMidline
        var offsetAccidental:Int? = nil
        
        if self.isOnlyRhythmNote {
            offsetFromMiddle = 0
        }
        if let writtenAccidental = self.accidental {
            //Content provided a specific accidental
            offsetAccidental = writtenAccidental
            if writtenAccidental != defaultNoteData.accidental {
                let defaultNoteStaffPlacement = staff.noteStaffPlacement[self.midiNumber]
                let targetOffsetIndex = self.midiNumber - writtenAccidental
                let targetNoteStaffPlacement = staff.noteStaffPlacement[targetOffsetIndex]
                let adjustOffset = defaultNoteStaffPlacement.offsetFromStaffMidline - targetNoteStaffPlacement.offsetFromStaffMidline
                offsetFromMiddle -= adjustOffset
//                print("===>Adjust note:", note.midiNumber, "adjOffset:", adjustOffset,
//                      "defaultOffset:", defaultNoteData.offsetFromStaffMidline, "newOffset:", offsetFromMiddle)
            }
        }
        else {
            //Determine if the note's accidental is implied by the key signature
            //Or a note has to have a natural accidental to offset the key signtue
            let keySignatureHasNote = staff.score.key.hasNote(note: self.midiNumber)
            if let defaultAccidental = defaultNoteData.accidental {
                if !keySignatureHasNote {
                    offsetAccidental = defaultAccidental
                }
            }
            else {
                let keySignatureHasNote = staff.score.key.hasNote(note: self.midiNumber + 1)
                if keySignatureHasNote {
                    offsetAccidental = 0
                }
            }
        }
        let placement = NoteStaffPlacement(midi: defaultNoteData.midi, offsetFroMidLine: offsetFromMiddle, accidental: offsetAccidental)
        return placement
    }
}
