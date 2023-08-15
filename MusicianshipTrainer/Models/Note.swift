import Foundation
import SwiftUI

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

enum NoteTag {
    case noTag
    case inError
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
        //self.name = name
    }
}

class Note : Hashable, Comparable, ObservableObject {
    @Published var hilite = false
    @Published var noteTag:NoteTag = .noTag
    static let MIDDLE_C = 60 //Midi pitch for C4
    static let OCTAVE = 12
    static let noteNames:[Character] = ["A", "B", "C", "D", "E", "F", "G"]
    
    static let VALUE_QUAVER = 0.5
    static let VALUE_QUARTER = 1.0
    static let VALUE_HALF = 2.0
    static let VALUE_WHOLE = 4.0

    let id = UUID()
    var midiNumber:Int
    var staffNum:Int? //Narrow the display of the note to just one staff
    
    private var value:Double = Note.VALUE_QUARTER
    var isDotted:Bool = false
    var isOnlyRhythmNote = false
    var accidental:Int? = nil //< 0 = flat, ==0 natural, > 0 sharp
    
    var sequence:Int = 0 //the note's sequence position 
    var rotated:Bool = false //true if note must be displayed vertically rotated due to closeness to a neighbor.
    
    var beamType:QuaverBeamType = .none
    //the note where the quaver beam for this note ends
    var beamEndNote:Note? = nil
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        //return lhs.midiNumber == rhs.midiNumber
        return lhs.id == rhs.id
    }
    static func < (lhs: Note, rhs: Note) -> Bool {
        return lhs.midiNumber < rhs.midiNumber
    }
    
    static func isSameNote(note1:Int, note2:Int) -> Bool {
        return (note1 % 12) == (note2 % 12)
    }
    
    init(num:Int, value:Double = Note.VALUE_QUARTER, accidental:Int?=nil, staffNum:Int? = nil, isDotted:Bool = false) {
        self.midiNumber = num
        self.staffNum = staffNum
        self.value = value
        self.isDotted = isDotted
        self.accidental = accidental
        if value == 3.0 {
            self.isDotted = true
        }
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
    
    func setNoteTag(_ tag: NoteTag) {
        DispatchQueue.main.async {
            self.noteTag = tag
        }
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
        case 2.0 :
            name += "minim"
        case 3.0 :
            name += "minim"
        default :
            name += "semibreve"
        }
        return name
    }
    
    func setIsOnlyRhythm(way: Bool) {
        self.isOnlyRhythmNote = way
        if self.isOnlyRhythmNote {
            self.midiNumber = Note.MIDDLE_C + Note.OCTAVE - 1
        }
        
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(midiNumber)
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
    
    func getBeamStartNote(score:Score, np: NoteLayoutPositions) -> Note {
        let endNote = self
        if endNote.beamType != .end {
            return endNote
        }
        var result:Note? = nil
        var idx = score.scoreEntries.count - 1
        var foundEnd = false
        while idx>=0 {
            let ts = score.scoreEntries[idx]
            if ts is TimeSlice {
                let notes = ts.getNotes()
                if let notes = notes {
                    if notes.count > 0 {
                        let note = notes[0]
                        if note.sequence == endNote.sequence {
                            foundEnd = true
                        }
                        else {
                            if foundEnd && note.beamType == .start {
                                result = note
                                break
                            }
                        }
                    }
                }
            }
            if ts is BarLine {
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
        if noteTag == .inError {
            return Color(.red)
        }
        if noteTag == .renderedInError {
            return Color(.clear)
        }
        if noteTag == .hilightExpected {
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
    func noteOffsetFromMiddle(staff:Staff) -> NoteStaffPlacement {
        let defaultNoteData = staff.getNoteViewPlacement(note: self)
        var offsetFromMiddle = defaultNoteData.offsetFromStaffMidline
        var offsetAccidental:Int? = nil
        
        if self.isOnlyRhythmNote {
            offsetFromMiddle = 0
        }
        if let writtenAccidental = self.accidental {
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
            if let defaultAccidental = defaultNoteData.accidental {
                offsetAccidental = defaultAccidental
            }
        }
        let placement = NoteStaffPlacement(midi: defaultNoteData.midi, offsetFroMidLine: offsetFromMiddle, accidental: offsetAccidental)
        return placement
    }
}
