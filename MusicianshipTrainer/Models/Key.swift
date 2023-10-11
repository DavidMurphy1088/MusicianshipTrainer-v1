class Key : Equatable, Hashable {
    var keySig: KeySignature
    var type: KeyType
    
    enum KeyType {
        case major
        case minor
    }
        
    static func == (lhs: Key, rhs: Key) -> Bool {
        return (lhs.type == rhs.type) && (lhs.keySig.accidentalCount == rhs.keySig.accidentalCount) &&
        (lhs.keySig.accidentalType == rhs.keySig.accidentalType)
    }
    
    init(type: KeyType, keySig:KeySignature) {
        self.keySig = keySig
        self.type = type
    }
    
    func hasNote(note:Int) -> Bool {
        var result:Bool = false
        for n in keySig.sharps {
            let octaves = Note.getAllOctaves(note: n)
            if octaves.contains(note) {
                result = true
                break
            }
        }
        return result
    }
    
    ///Return the chord triad type for a scale degree
    func getTriadType(scaleOffset: Int) -> Chord.ChordType {
        if self.type == KeyType.major {
            if ([0, 5, 7].contains(scaleOffset)) {
                return Chord.ChordType.major
            }
            if ([11].contains(scaleOffset)) {
                return Chord.ChordType.diminished
            }
            return Chord.ChordType.minor
        }
        else {
            if ([0, 5, 7].contains(scaleOffset)) {
                return Chord.ChordType.minor
            }
            if ([2].contains(scaleOffset)) {
                return Chord.ChordType.diminished
            }
            return Chord.ChordType.major
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(keySig.accidentalCount)
    }
    
    func description() -> String {
        var desc = ""
        if keySig.accidentalType == AccidentalType.sharp {
            switch self.keySig.accidentalCount {
            case 0:
                desc = self.type == KeyType.major ? "C" : "A"
            case 1:
                desc = self.type == KeyType.major ? "G" : "E"
            case 2:
                desc = self.type == KeyType.major ? "D" : "B"
            case 3:
                desc = self.type == KeyType.major ? "A" : "F#"
            case 4:
                desc = self.type == KeyType.major ? "E" : "C#"
            default:
                desc = "unknown"
            }
        }
        else {
            switch self.keySig.accidentalCount {
            case 0:
                desc = self.type == KeyType.major ? "C" : "A"
            case 1:
                desc = self.type == KeyType.major ? "F" : "D"
            case 2:
                desc = self.type == KeyType.major ? "B"+Score.accFlat : "G"
            case 3:
                desc = self.type == KeyType.major ? "E"+Score.accFlat : "C"
            case 4:
                desc = self.type == KeyType.major ? "A"+Score.accFlat : "F"
            case 5:
                desc = self.type == KeyType.major ? "D"+Score.accFlat : "B"+Score.accFlat
            case 6:
                desc = self.type == KeyType.major ? "G"+Score.accFlat : "E"+Score.accFlat
            default:
                desc = "unknown"
            }

        }
        switch self.type {
        case KeyType.major:
            desc += " Major"
        case KeyType.minor:
            desc += " Minor"
        }
        return desc
    }
    
    func getKeyTagName() -> String {
        let keyTag:String
        switch keySig.accidentalCount {
        case 1:
            keyTag = "G"
        case 2:
            keyTag = "D"
        case 3:
            keyTag = "A"
        case 4:
            keyTag = "E"
        case 5:
            keyTag = "B"
        default:
            keyTag = "C"
        }
        return keyTag
    }
    
    func firstScaleNote() -> Int {

        var base = 60
        switch keySig.accidentalCount {
        case 0:
            base = 48
        case 1:
            base = 43
        case 2:
            base = 50
        case 3:
            base = 45
        case 4:
            base = 40
        case 5:
            base = 47
        default:
            base = 60
        }
        return base
    }
    
//    func makeKeyTriad(value:Double, staffNum:Int) -> [Note] {
//        let rootMidi:Int
//        switch keySig.accidentalCount {
//        case 1:
//            rootMidi = 43
//        case 2:
//            rootMidi = 50
//        case 3:
//            rootMidi = 45
//        case 4:
//            rootMidi = 52
//        case 5:
//            rootMidi = 47
//        default:
//            rootMidi = 48
//        }
//        var result:[Note] = []
//        result.append(Note(num: rootMidi, value: value, staffNum: staffNum))
//        result.append(Note(num: rootMidi + 4, value: value, staffNum: staffNum))
//        result.append(Note(num: rootMidi + 7, value: value, staffNum: staffNum))
//        return result
//    }
//
    func getScaleStartMidi() -> Int {
        let rootMidi:Int
        switch keySig.accidentalCount {
        case 1:
            rootMidi = 43
        case 2:
            rootMidi = 50
        case 3:
            rootMidi = 45
        case 4:
            rootMidi = 52
        case 5:
            rootMidi = 47
        default:
            rootMidi = 48
        }
        return rootMidi
    }
    
    func makeTriadAt(timeSlice:TimeSlice, rootMidi:Int, value:Double, staffNum:Int) -> [Note] {
        var result:[Note] = []
        result.append(Note(timeSlice:timeSlice, num: rootMidi, value: value, staffNum: staffNum))
        result.append(Note(timeSlice:timeSlice, num: rootMidi + 4, value: value, staffNum: staffNum))
        result.append(Note(timeSlice:timeSlice, num: rootMidi + 7, value: value, staffNum: staffNum))
        return result
    }

}
