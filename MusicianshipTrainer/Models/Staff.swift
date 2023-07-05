import Foundation
import AVKit
import AVFoundation

//https://mammothmemory.net/music/sheet-music/reading-music/treble-clef-and-bass-clef.html

//used to record view positions of notes as they are drawn by a view so that a 2nd drwing pass can draw quaver beams to the right points
class NoteLayoutPositions: ObservableObject {
    @Published var positions:[Note: CGRect] = [:]

    var id:Int
    static var nextId = 0
    
    init(id:Int) {
        self.id = id
    }
    
    static func getShared() -> NoteLayoutPositions {
        let lp = NoteLayoutPositions(id: nextId)
        nextId += 1
        return lp
    }
    
    func storePosition(note: Note, rect: CGRect, cord:String) {
        if note.beamType != .none {
            let rectCopy = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY), size: CGSize(width: rect.size.width, height: rect.size.height))
            DispatchQueue.main.async {
                sleep(UInt32(0.25))
                self.positions[note] = rectCopy //rect
            }
        }
    }
}

enum StaffType {
    case treble
    case bass
}

class NoteStaffPlacement {
    var name:Character
    var offsetFromStaffMidline:Int
    var acc: Int?
    init(name:Character, offsetFroMidLine:Int, _ acc:Int?=nil) {
        self.offsetFromStaffMidline = offsetFroMidLine
        self.acc = acc
        self.name = name
    }
}

class StaffPlacementsByKey {
    var staffPlacement:[NoteStaffPlacement] = []
}

class NoteOffsetsInStaffByKey {
    var noteOffsetByKey:[String] = []
    init () {
        // offset, sign. sign = ' ' or 0=flat, 1=natural, 2=sharp
        //  Key                 C    D♭   D    E♭   E    F    G♭   G    A♭   A    B♭   B
        noteOffsetByKey.append("0    0    0,1  0    0,1  0    0,1  0    0    0,1  0    0,0")  //C
        noteOffsetByKey.append("0,2  1    0    1,0  0    1,0  1    0,2  1    0    1,0  0,0")  //C#
        noteOffsetByKey.append("1    1,1  1    1    1,1  1    1,1  1    1,1  1    1    0,0")  //D
        noteOffsetByKey.append("2,0  2    2,0  2    1    2,0  2    2,0  2    1,2  2    0,0")  //E♭
        noteOffsetByKey.append("2    2,1  2    2,1  2    2    2,1  2    2,1  2    2,1  0,0")  //E
        noteOffsetByKey.append("3    3    3,1  3    3,1  3    3    3,1  3    3,1  3    0,0")  //F
        noteOffsetByKey.append("3,2  4    3    4,0  3    4,0  4    3    4,0  3    4,0  0,0")  //F#
        noteOffsetByKey.append("4    4,1  4    4    4,1  4    4,1  4    4    4,1  4    0,0")  //G
        noteOffsetByKey.append("4,2  5    4,2  5    4    5,0  5    4,2  5    4    5,0  0,0")  //G#
        noteOffsetByKey.append("5    5,1  5    5,1  5    5    5,1  5    5,1  5    5    0,0")  //A
        noteOffsetByKey.append("6,0  6    6,0  6    6,0  6    6    6,0  6    6,0  6    0,0")  //B♭
        noteOffsetByKey.append("6    6,1  6    6,1  6    6,1  6,1  6    6,1  6    6,1  0,0")  //B
    }
}

class Staff : ObservableObject {
    let id = UUID()
    @Published var publishUpdate = 0
    @Published var noteLayoutPositions:NoteLayoutPositions //.getShared()
    @Published var isHidden:Bool = false

    let score:Score
    var type:StaffType
    var staffNum:Int
    var lowestNoteValue:Int
    var highestNoteValue:Int
    var middleNoteValue:Int
    var staffOffsets:[Int] = []
    var noteStaffPlacement:[NoteStaffPlacement]=[]
    var linesInStaff:Int
    
    init(score:Score, type:StaffType, staffNum:Int, linesInStaff:Int) {
        self.score = score
        self.type = type
        self.staffNum = staffNum
        self.linesInStaff = linesInStaff
        lowestNoteValue = 20 //MIDI C0
        highestNoteValue = 107 //MIDI B7
        middleNoteValue = type == StaffType.treble ? 71 : Note.MIDDLE_C - Note.OCTAVE + 2
        noteLayoutPositions = NoteLayoutPositions(id: 0)
        
        //Determine the staff placement for each note pitch
        var noteOffsets:[Int] = []
        for line in NoteOffsetsInStaffByKey().noteOffsetByKey {
            let f = String(line.components(separatedBy: " ")[0])
            //noteOffsetEntries.append(pairs) //Just C Major
            let fx:String = String(f.first!)
            var off = Int(fx)
            noteOffsets.append((off == nil ? 0 : off)!)
        }
        
        for noteValue in 0...highestNoteValue {
            //Hack - set the note off the staff (i.e invisible) if its pitch is not mapped to the staff lines
            //Fix - make sure both staff types have offset set for their full pitch ranges
            //Fix - longer - offset should be from middle C, notes should be displayed on both staffs from a single traversal of the score's timeslices
            
            var placement = NoteStaffPlacement(name: "X", offsetFroMidLine: 100)
            noteStaffPlacement.append(placement)
            if noteValue <= middleNoteValue - 12 || noteValue >= middleNoteValue + 12 {
                continue
            }
            var diff = noteValue - middleNoteValue
            var noteOffsetInScale = 0
            if diff > 0 {
                noteOffsetInScale = noteOffsets[diff - 1]
            }
            else {
                let n = noteOffsets.count + diff - 1
                if diff >= n {
                    diff = diff - 12
                }
                noteOffsetInScale = noteOffsets[n]
                noteOffsetInScale =  noteOffsetInScale - 7
            }
            
            var name = ""
            name = "X" //String(Note.noteNames[(noteOffsetInScale+2) % Note.noteNames.count])
            let offset = noteOffsetInScale + 1
            placement = NoteStaffPlacement(name: "X", offsetFroMidLine: offset)
            noteStaffPlacement[noteValue] = placement
        }
    }
    
    func keyDescription() -> String {
        return self.score.key.description()
    }
    
    func update() {
        DispatchQueue.main.async {
            self.publishUpdate += 1
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.publishUpdate = 0
        }
    }
    
    func keyColumn() -> Int {
        //    Key   C    D♭   D    E♭   E    F    G♭   G    A♭   A    B♭   B
        //m.append("0    0    0,0  0    0,0  0    0    0    0    0,0  0    0,0")  //C

        if score.key.keySig.accidentalType == AccidentalType.sharp {
            switch score.key.keySig.accidentalCount {
            case 0:
                return 0
            case 1:
                return 7
            case 2:
                return 2
            case 3:
                return 9
            case 4:
                return 4
            case 5:
                return 11
            case 6:
                return 6
            case 7:
                return 1
            default:
                return 0
            }
        }
        else {
            switch score.key.keySig.accidentalCount {
            case 0:
                return 0
            case 1:
                return 5
            case 2:
                return 10
            case 3:
                return 3
            case 4:
                return 8
            case 5:
                return 1
            case 6:
                return 6
            case 7:
                return 11
            default:
                return 0
            }
        }
     }
    
    //Tell a note how to display itself
    //func getNoteViewData(noteValue:Int) -> (Int, String, [Int]) {
    func getNoteViewData(noteValue:Int) -> (Int, [Int]) {
        var offset = 0
        if self.type == .treble {
            if noteValue >= noteStaffPlacement.count {
                
            }
            offset = noteStaffPlacement[noteValue].offsetFromStaffMidline
        }
        else {
            offset = noteStaffPlacement[noteValue].offsetFromStaffMidline
        }
        var ledgerLines:[Int] = []
        return (offset, ledgerLines)
    }
    
}
 
