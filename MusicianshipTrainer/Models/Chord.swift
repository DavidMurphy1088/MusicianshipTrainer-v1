class Chord : Identifiable {
    private var notes:[Note] = []
    
    enum ChordType {
        case major
        case minor
        case diminished
    }
    
    init() {
    }
    
    func makeTriad(root: Int, type:ChordType) {
        notes.append(Note(num: root))
        if type == ChordType.major {
            notes.append(Note(num: root+4))
        }
        else {
            notes.append(Note(num: root+3))
        }
        if type == ChordType.diminished {
            notes.append(Note(num: root+6))
        }
        else {
            notes.append(Note(num: root+7))
        }
    }
    
    func addNote(note:Note) {
        self.notes.append(note)
        self.notes.sort()
        //check for adjoing 2nds which have to be displayed twisted
        for n in 0..<self.notes.count-1 {
            let note = self.notes[n]
            let above = self.notes[n+1]
            if above.midiNumber - note.midiNumber <= 3 {
                note.rotated = true
            }
        }
    }
    
    func getNotes() -> [Note] {
        return self.notes
    }

    /// Dont double the 3rd
    /// Keep each voice within one octave of the one below except for tenor down to base
    func makeSATBFourNote() -> Chord {
        let result = Chord()
        var desiredPitch = Note.MIDDLE_C - Note.OCTAVE
        let baseNote = Note.getClosestOctave(note: self.notes[0].midiNumber, toPitch: desiredPitch)
        result.notes.append(Note(num: baseNote, staffNum: 1))
        let voiceGap = Note.OCTAVE/2 // + 3
        
        //choose the tenor as triad note 1 or 2
        let tenorCandidates = [1,2]
        desiredPitch = baseNote + voiceGap //+ 2// + voiceGap/2
        var minDiff = 1000
        var tenorChoiceIndex = 0
        var tenorNote = 0
        for c in tenorCandidates {
            let closest = Note.getClosestOctave(note: self.notes[c].midiNumber, toPitch: desiredPitch, onlyHigher: true)
            let diff = abs(closest - desiredPitch)
            if diff < minDiff {
                minDiff = diff
                tenorChoiceIndex = c
                tenorNote = closest
            }
        }
        result.notes.append(Note(num: tenorNote, staffNum: 1))
        
        //choose the alto
        desiredPitch = tenorNote + voiceGap
        var altoCandidates = [0, 2]
        if tenorChoiceIndex != 1 { //dont double the 3rd
            altoCandidates.append(1)
        }

        minDiff = Int.max
        var altoChoiceIndex = 0
        var altoNote = 0
        for c in altoCandidates {
            let closest = Note.getClosestOctave(note: self.notes[c].midiNumber, toPitch: desiredPitch, onlyHigher: true)
            let diff = abs(closest - desiredPitch)
            if diff < minDiff {
                minDiff = diff
                altoChoiceIndex = c
                altoNote = closest
            }
        }
        result.notes.append(Note(num: altoNote, staffNum: 0))

        //choose the soprano
        desiredPitch = altoNote + voiceGap
        var sopranoCandidates = [0, 2]
        if tenorChoiceIndex != 1 && altoChoiceIndex != 1 {
            sopranoCandidates = [1] //only the 3rd is allowed - the 3rd must be present
        }
        
        minDiff = Int.max
        var sopranoNote = 0
        for c in sopranoCandidates {
            let closest = Note.getClosestOctave(note: self.notes[c].midiNumber, toPitch: desiredPitch, onlyHigher: true)
            let diff = abs(closest - desiredPitch)
            if diff < minDiff {
                minDiff = diff
                sopranoNote = closest
            }
        }
        result.notes.append(Note(num: sopranoNote, staffNum: 0))
        return result
    }

    func addSeventh() {
        let n = self.notes[0].midiNumber
        self.notes.append(Note(num: n+10))
    }
    
    func makeInversion(inv: Int) -> Chord {
        let res = Chord()
        for i in 0...self.notes.count-1 {
            let j = (i + inv)
            var n = self.notes[j % self.notes.count].midiNumber
            if j >= self.notes.count {
                n += 12
            }
            res.notes.append(Note(num: n))
        }
        return res
    }
    
    ///Return a chord based on the notes of the toChordTriad that is a voice led cadence from the self chord
    ///TODO - add rules to ensue 3rd always added and avoid parallet 5ths and octaves
    func makeCadenceWithVoiceLead(toChordTriad: Chord) -> Chord {
        var result:[Int] = []
        
        let destinationRoot = toChordTriad.notes[0].midiNumber
        let leadingRoot = notes[0].midiNumber
        let closestRoot = Note.getClosestOctave(note: destinationRoot, toPitch: leadingRoot)
        result.append(closestRoot)
        
        for n in 1..<notes.count {

            let fromNote = notes[n].midiNumber
            
            var leastDiff = Int.max
            var bestNote = 0

            for m in toChordTriad.notes {
                let toNoteOctaves = Note.getAllOctaves(note: m.midiNumber)
                for toNoteOctave in toNoteOctaves {
                    if result.contains(toNoteOctave) {
                        continue
                    }
                    let diff = abs(toNoteOctave - fromNote)
                    if diff < leastDiff {
                        leastDiff = diff
                        bestNote = toNoteOctave
                    }
                }
            }
            result.append(bestNote)
            if n == 33 {
                break
            }
        }
        
        let resultChord = Chord()
        for n in 0..<result.count {
            resultChord.notes.append(Note(num: result[n], staffNum: n < 2 ? 1 : 0))
        }
        return resultChord
    }
    
    func moveClosestTo(pitch: Int, index: Int) {
        let pitch = Note.getClosestOctave(note: self.notes[index].midiNumber, toPitch: pitch)
        let offset = self.notes[index].midiNumber - pitch
        for i in 0...self.notes.count-1 {
            self.notes[i].midiNumber -= offset
        }
    }
    
    func toStr() -> String {
        var s = ""
        for note in self.notes {
            //var n = (note.num % Note.noteNames.count)...
            s += "\(note.midiNumber)  "
        }
        return s
    }
    
    func makeVoiceLead(to:Chord) -> Chord {
        let result = Chord()
        var unusedPitches:[Int] = []
        for t in to.notes {
            unusedPitches.append(t.midiNumber)
        }
        var done:[Int] = []
        var log:[(Int, Int, Int)] = []
        
        // for each from chord note find the closest unused degree chord note
        
        while done.count < self.notes.count {
            var fromIdx = -1
            while true {
                fromIdx = Int.random(in: 0..<self.notes.count)
                if !done.contains(fromIdx) {
                    break
                }
            }
            var bestPitch = 0
            if unusedPitches.count > 0 {
                var minDiff = 1000
                var mi = 0
                for uindex in 0..<unusedPitches.count {
                    let closest = Note.getClosestOctave(note:unusedPitches[uindex], toPitch:notes[fromIdx].midiNumber)
                    let diff = abs(closest - notes[fromIdx].midiNumber)
                    if diff < minDiff {
                        minDiff = diff
                        mi = uindex
                        bestPitch = closest
                    }
                }
                unusedPitches.remove(at: mi)
            }
            else {
                for t in to.notes {
                    unusedPitches.append(t.midiNumber+12)
                    unusedPitches.append(t.midiNumber-12)
                }
                continue
            }
            if bestPitch > 0 {
                let bestNote = Note(num: bestPitch)
                bestNote.staffNum = notes[fromIdx].staffNum
                result.notes.append(bestNote)
            }
            done.append(fromIdx)
            log.append((self.notes[fromIdx].midiNumber, bestPitch, done.count))
        }
        let ls = log.sorted {
            $0.0 < $1.1
        }

        result.order()
        return result
    }
    
    func order() {
        notes.sort {
            $0.midiNumber < $1.midiNumber
        }
    }
    
    //“SATB” refers to four-part chords scored for soprano (S), alto (A), tenor (T), and bass (B) voices. Three-part chords are often specified as SAB (soprano, alto, bass) but could be scored for any combination of the three voice types. SATB voice leading will also be referred to as “chorale-style” voice leading.
    func makeSATB() -> Chord {
        let result = Chord()
        var nextPitch = abs(Note.getClosestOctave(note: self.notes[0].midiNumber, toPitch: Note.MIDDLE_C - 12 - 3))
        for voice in 0..<4 {
            var bestPitch = 0
            var lowestDiff:Int? = nil
            for i in 0..<self.notes.count {
                let closestPitch = abs(Note.getClosestOctave(note: self.notes[i].midiNumber, toPitch: nextPitch))
                let diff = abs(closestPitch - nextPitch)
                if lowestDiff == nil || diff < lowestDiff! {
                    lowestDiff = diff
                    bestPitch = closestPitch
                }
            }
            let note = Note(num: bestPitch)
            if [0,1].contains(voice) {
                note.staffNum = 1
            }
            result.notes.append(note)
            if voice == 1 {
                nextPitch += 12
            }
            else {
                nextPitch += 8
            }
        }
        result.order()
        return result
    }
}
