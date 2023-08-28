import SwiftUI
import CoreData
import AVFoundation

class Metronome: ObservableObject {
    
    static private var shared:Metronome = Metronome()
    static private var nextInstrument = 0
    
    let id = UUID()
    @Published var clapCounter = 0
    @Published var tempoName:String = ""
    @Published var tempo:Int = 60
    @Published var allowChangeTempo:Bool = false
    @Published var tickingIsActive = false
    @Published var speechEnabled = false

    let tempoMinimumSetting = 60
    let tempoMaximumSetting = 120
    var setCtr = 0

    private var clapCnt = 0
    private var isThreadRunning = false
    private var score:Score?
    private var nextScoreIndex = 0
    private var nextScoreTimeSlice:TimeSlice?
    private var currentNoteTimeToLive = 0.0

    //the shortest note value which is used to set the metronome's thread firing frequency
    private let shortestNoteValue = Note.VALUE_QUAVER
    private let speech = SpeechSynthesizer.shared
    private var onDoneFunction:(()->Void)? = nil
    
    static func getMetronomeWithSettings(initialTempo:Int, allowChangeTempo:Bool, ctx:String) -> Metronome {
        shared.setTempo(tempo: initialTempo, context: "getMetronomeWithSettings - \(ctx)")
        shared.allowChangeTempo = allowChangeTempo
        //print("** Get Metronome, WithSettings (Specific), ID:", "tempo:", Metronome.shared.tempo, ctx)
        return Metronome.shared
    }

    static func getMetronomeWithCurrentSettings(ctx:String) -> Metronome {
        //print("** Get Metronome, Current Settings, ID:", "tempo:", Metronome.shared.tempo, ctx)
        return Metronome.shared
    }
//
//    static func getMetronomeWithStandardSettings(ctx:String) -> Metronome {
//        let met = Metronome.getMetronomeWithSettings(initialTempo: 60, allowChangeTempo: false, ctx: "getMetronomeWithStandardSettings - \(ctx)")
//        print("** Get Metronome, Standard Settings, ID:", "tempo:", met.tempo)
//        return met
//    }

    private init() {
    }
    
    func setSpeechEnabled(enabled:Bool) {
        DispatchQueue.main.async {
            self.speechEnabled = enabled
        }
    }
    
    func startTicking(score:Score) {
        let audioSamplerMIDI = AudioSamplerPlayer.shared.sampler //getMidiAudioSampler()
        //let audioTicker:AudioSamplerPlayer = AudioSamplerPlayer(timeSignature: score.timeSignature)
        //setTempo(tempo: self.tempo)
        DispatchQueue.main.async {
            self.tickingIsActive = true
            if !self.isThreadRunning {
                self.startThreadRunning(timeSignature: score.timeSignature, audioSamplerPlayerMIDI:audioSamplerMIDI)
            }
        }
    }
    
    func stopTicking() {
        DispatchQueue.main.async {
            self.tickingIsActive = false
        }
    }

    func setTempo(tempo: Int, context:String, allowBeyondLimits:Bool = false) {
        //https://theonlinemetronome.com/blogs/12/tempo-markings-defined
        //print("------> SET Metronome START, SET TEMPO ctr:", self.setCtr, "ctx:[\(context)]",  "\tcurrent:", self.tempo, "\trequested:", tempo)

        var tempoToSet:Int
        var maxTempo = self.tempoMaximumSetting
        var minTempo = self.tempoMinimumSetting
        
        if allowBeyondLimits {
            maxTempo = 250
            minTempo = 50
        }
        if tempo < minTempo {
            tempoToSet = minTempo
        }
        else {
            if tempo > maxTempo {
                tempoToSet = maxTempo
            }
            else {
                tempoToSet = tempo
            }
        }
        
        if self.tempo == tempoToSet {
            return
        }
        setCtr += 1

        var name = ""
        if tempoToSet <= 20 {
            name = "Larghissimo"
        }
        if tempoToSet > 20 && tempo <= 40 {
            name = "Solenne/Grave"
        }
        if tempoToSet > 40 && tempo <= 59 {
            name = "Lento"
        }
        if tempoToSet > 59 && tempo <= 72 {
            name = "Adagio"
        }
        if tempoToSet > 72 && tempo <= 76 {
            name = "Andante"
        }
        if tempoToSet > 76 && tempo <= 83 {
            name = "Andantino"
        }
        if tempoToSet > 83  && tempo <= 120 {
            name = "Moderato"
        }
        if tempoToSet > 120  && tempo <= 128 {
            name = "Allegretto"
        }
        if tempoToSet > 128  && tempo <= 180 {
            name = "Allegro"
        }
        if tempoToSet > 180  {
            name = "Presto"
        }
        if tempoToSet > 200 {
            name = "*"
        }
        DispatchQueue.main.async {
            self.tempo = tempoToSet
            self.tempoName = name
            //print("------> SET Metronome END  , SET TEMPO ctr:", self.setCtr, "ctx:[\(context)]",  "\tcurrent:", self.tempo, "\trequested:", tempo)

        }
    }
    
    func setAllowTempoChange(allow:Bool) {
        DispatchQueue.main.async {
            self.allowChangeTempo = allow
        }
    }
    
    func playScore(score:Score, rhythmNotesOnly:Bool=false, onDone: (()->Void)? = nil) {
        let audioSamplerMIDI = AudioSamplerPlayer.shared.sampler //getMidiAudioSampler()

        //find the first note to play
        nextScoreIndex = 0
        if score.scoreEntries.count > 0 {
            if score.scoreEntries[0] is TimeSlice {
                let next = score.scoreEntries[0] as! TimeSlice
                if next.notes.count > 0 {
                    self.score = score
                    self.nextScoreTimeSlice = next
                    self.currentNoteTimeToLive = nextScoreTimeSlice!.notes[0].getValue()
                    self.onDoneFunction = onDone
                }
            }
        }
        if self.nextScoreTimeSlice == nil {
            return
        }
        nextScoreIndex = 1
        if !self.isThreadRunning {
            startThreadRunning(timeSignature: score.timeSignature, audioSamplerPlayerMIDI:audioSamplerMIDI)
        }
        //setTempo(tempo: self.tempo, context: "Metronome start playScore")
    }
    
    func stopPlayingScore() {
        DispatchQueue.main.async {
            self.score = nil
            //let audioUnitSampler:AVAudioUnitSampler = self.getMidiAudioSampler()
            let audioUnitSampler = AudioSamplerPlayer.shared.sampler
            for m in 58...74 {
                audioUnitSampler.stopNote(UInt8(m), onChannel: UInt8(0))
            }
            audioUnitSampler.reset()
        }

    }

    private func startThreadRunning(timeSignature:TimeSignature, audioSamplerPlayerMIDI:AVAudioUnitSampler?) {
        self.isThreadRunning = true
        
        let audioTickerMetronomeTick:AudioTicker = AudioTicker(timeSignature: timeSignature, tickStyle: true)
        let audioClapper:AudioTicker = AudioTicker(timeSignature: timeSignature, tickStyle: false)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            var loopCtr = 0
            var keepRunning = true
            var currentTimeValue = 0.0
            var noteValueSpeechWord:String? = nil
            var ticksPlayed = 0
            var firstNote = true
            var currentRestTimeToLive = 0.0
            
            while keepRunning {
                noteValueSpeechWord = nil
                //print("\nthread loop", loopCtr, "score:", score, "next ts:", nextScoreTimeSlice, "firstNote", firstNote)

                // sound the metronome tick. %2 because its counting at quaver intervals
                // Make sure score playing is synched to the metronome tick

                if loopCtr % 2 == 0 {
                    if self.tickingIsActive {
                        audioTickerMetronomeTick.soundTick()
                        ticksPlayed += 1
                    }
                }
                
                //sound the next note

                if (firstNote && loopCtr % 2 == 0) || (!firstNote) {
                    //just process rests like notes but dont sound them. But adjust sound tick's counting'
                    if let score = score {
                        firstNote = false
                        if let timeSlice = nextScoreTimeSlice {
                            var noteInChordNum = 0
                            if timeSlice.notes.count > 0 {
                                let topNote = timeSlice.notes[0]
                                if currentNoteTimeToLive >= topNote.getValue() {
                                    for note in timeSlice.notes {
                                        if note.isOnlyRhythmNote  {
                                            audioClapper.soundTick(noteValue: note.getValue())
                                        }
                                        else {
                                            //print(" --- Score play note", loopCtr, "next score time slice", nextScoreTimeSlice)
                                            if let audioPlayer = audioSamplerPlayerMIDI {
                                                audioPlayer.startNote(UInt8(note.midiNumber), withVelocity:64, onChannel:UInt8(0))
                                            }
                                        }
                                        if noteInChordNum == 0 && note.getValue() < 1.0 {
                                            noteValueSpeechWord = "and"
                                        }
                                        noteInChordNum += 1
                                    }
                                    
                                    topNote.setHilite(hilite: true)
                                    DispatchQueue.global(qos: .background).async {
                                        Thread.sleep(forTimeInterval: 0.5)
                                        topNote.setHilite(hilite: false)
                                    }
                                }
                            }

                            
                            //determine what time slice comes on the next tick. e.g. possibly for a long note the current time slice needs > 1 tick
                            //print("============", nextScoreIndex, currentNoteTimeToLive, currentRestTimeToLive, "idx")
                            currentNoteTimeToLive -= self.shortestNoteValue
//                            if currentNoteTimeToLive <= 0 {
//                                currentRestTimeToLive -= self.shortestNoteValue
//                            }
                            
                            if currentNoteTimeToLive <= 0 {
                                //look for the next note to play
                                nextScoreTimeSlice = nil
                                while nextScoreIndex < score.scoreEntries.count {
                                    let entry = score.scoreEntries[nextScoreIndex]
                                    if entry is TimeSlice {
                                        nextScoreTimeSlice = entry as! TimeSlice
                                        if nextScoreTimeSlice!.notes.count > 0 {
                                            nextScoreIndex += 1
                                            currentNoteTimeToLive = nextScoreTimeSlice!.notes[0].getValue()
                                            if nextScoreIndex < score.scoreEntries.count {
                                                let x = score.scoreEntries[nextScoreIndex]
                                                if x is Rest {
                                                    let rest = x as! Rest
                                                    currentRestTimeToLive = rest.value
                                                }
                                            }
                                            break
                                        }
                                        else {
                                            let barLine = entry as! BarLine
                                            if barLine != nil {
                                                currentTimeValue = 0
                                            }
                                        }
                                    }
                                    
                                    nextScoreIndex += 1
                                }
                            }
                        }
                    }
                }

                if speechEnabled {
                    if loopCtr % 2 == 0 {
                        let word = noteCoundSpeechWord(currentTimeValue: currentTimeValue)
                        speech.speakWord(word)
                    }
                    else {
                        //quavers say 'and'
                        if noteValueSpeechWord != nil {
                            speech.speakWord(noteValueSpeechWord!)
                        }
                    }
                }
                currentTimeValue += shortestNoteValue
                
                if score == nil {
                    firstNote = true
                }
                else {
                    if nextScoreTimeSlice == nil {
                        if self.onDoneFunction != nil {
                            self.onDoneFunction!()
                        }
                        self.onDoneFunction = nil
                        score = nil
                        firstNote = true
                    }
                }

                if !tickingIsActive {
                    keepRunning = score != nil
                }

                if keepRunning {
                    let sleepTime = (60.0 / Double(self.tempo)) * shortestNoteValue
                    Thread.sleep(forTimeInterval: sleepTime)
                    loopCtr += 1
                }
            }
            self.isThreadRunning = false
            //print("====>Thread ENDED")
        }
    }

    func noteCoundSpeechWord(currentTimeValue:Double) -> String {
        var word = ""
        if currentTimeValue.truncatingRemainder(dividingBy: 1) == 0 {
            let cvInt = Int(currentTimeValue)
            if let score = score {
                switch cvInt %  score.timeSignature.top {
                case 0 :
                    word = "one"
                    
                case 1 :
                    word = "two"
                    
                case 2 :
                    word = "three"
                    
                default :
                    word = "four"
                }
            }
        }
        else {
            word = ""
        }
        return word
    }
    
}

