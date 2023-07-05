import Foundation
import AVKit
import AVFoundation

class KeySignature {
    var accidentalType:AccidentalType
    var sharps:[Int] = []
    var flats:[Int] =  []
    var accidentalCount:Int
    var maxAccidentals = 7
    
    init(type:AccidentalType, count:Int) {
        self.accidentalType = type
        self.accidentalCount = count
        for i in 0..<count {
            sharps.append(45 + i*7)
            flats.append(39 + i*5)
        }
    }

    // how frequently is this note in a key signature
    func accidentalFrequency(note:Int, sigType: AccidentalType) -> Int {
        var pos:Int?
        if sigType == AccidentalType.sharp {
            for i in 0...sharps.count-1 {
                if Note.isSameNote(note1: note, note2: sharps[i]) {
                    pos = i
                    break
                }
            }
        }
        else {
            for i in 0...flats.count-1 {
                if Note.isSameNote(note1: note, note2: flats[i]) {
                    pos = i
                    break
                }
            }
        }
        if let pos = pos {
            return maxAccidentals - pos
        }
        else {
            return 0
        }
    }
    
}
