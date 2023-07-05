
import Foundation

class Scale {
    var notes:[Note] = []
    var score:Score
    
    enum MinorType {
        case natural
        case harmonic
        case melodic
    }

    init(score:Score) {
        self.score = score
        //self.minorType = minorType
        var num = score.key.firstScaleNote()
        for i in 0..<7 {
            notes.append(Note(num: num, value: 1))
            if score.key.type == Key.KeyType.major {
                if [2,6].contains(i) {
                    num += 1
                }
                else {
                    num += 2
                }
            }
            else {
                if [1,4].contains(i) {
                    num += 1
                }
                else {
                    num += 2
                }
            }
        }
        if self.score.key.type == Key.KeyType.minor && self.score.minorScaleType == MinorType.harmonic {
            notes[6].midiNumber += 1
        }
    }
    
    func noteInScale(note: Note) -> Bool {
        for octaveOffset in 0...4 {
            if self.notes.contains(Note(num: note.midiNumber + octaveOffset*12, value: 1)){
                return true
            }
            if self.notes.contains(Note(num: note.midiNumber - octaveOffset*12, value: 1)){
                return true
            }
        }
        return false
    }
    
    //list the diatonic note offsets in the scale
    func diatonicOffsets() -> [Int] {
        if score.key.type == Key.KeyType.major {
            return [0, 2, 4, 5, 7, 9, 11]
        }
        else {
            if self.score.minorScaleType == MinorType.natural {
                return [0, 2, 3, 5, 7, 8, 10]
            }
            else {
                return [0, 2, 3, 5, 7, 8, 11]
            }
        }
    }
    
    //return the degree in the scale of a note offset
    func noteDegree(offset:Int) -> Int {
        if score.key.type == Key.KeyType.major {
            switch offset {
            case 0:
                return 1
            case 2:
                return 2
            case 4:
                return 3
            case 5:
                return 4
            case 7:
                return 5
            case 9:
                return 6
            case 11:
                return 7
            default:
                return 0
            }
        }
        else {
            switch offset {
            case 0:
                return 1
            case 2:
                return 2
            case 3:
                return 3
            case 5:
                return 4
            case 7:
                return 5
            case 8:
                return 6
            case 10:
                if score.minorScaleType == MinorType.natural {
                    return 7
                }
                return 0
            case 11:
                if score.minorScaleType == MinorType.harmonic {
                    return 7
                }
                return 0
            default:
                return 0
            }
        }
    }
    
    func offsetSymbol(degree: Int) -> String {
        if score.key.type == Key.KeyType.major {
            switch degree {
            case 0: return "I"
            case 2: return "ii"
            case 4: return "iii"
            case 5: return "IV"
            case 7: return "V"
            case 9: return "vi"
            case 11: return "vii°"
            default: return "\(degree)"
            }
        }
        else {
            switch degree {
            case 0: return "i"
            case 2: return "ii°"
            case 3: return "III"
            case 5: return "iv"
            case 7: return "V"
            case 8: return "VI"
            case 10: return "vii°"
            default: return "\(degree)"
            }
        }
    }
    
    func degreeName(degree: Int) -> String {
        switch degree {
        case 1: return "Tonic"
        case 2: return "Supertonic"
        case 3: return "Mediant"
        case 4: return "Subdominant"
        case 5: return "Dominant"
        case 6: return "Submediant"
        case 7:
            if score.minorScaleType == MinorType.harmonic {
                return "Leading Tone"
            }
            else {
                return "Subtonic"
            }
        default: return ""
        }
    }
}
