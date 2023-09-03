import SwiftUI
import CoreData
import AVFoundation

class TapRecorder : NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate, ObservableObject {
    static let shared = TapRecorder()
    
    @Published var status:String = ""
    @Published var enableRecordingLight = false
    
    var tapTimes:[Double] = []
    var tappedValues:[Double] = []

    var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "Tap Recorder init")
    var metronomeTempoAtRecordingStart:Int? = nil
    
    func setStatus(_ msg:String) {
        DispatchQueue.main.async {
            self.status = msg
        }
    }
    
    func startRecording(metronomeLeadIn:Bool, metronomeTempoAtRecordingStart:Int)  {
        self.tappedValues = []
        self.tapTimes = []
        if metronomeLeadIn {
            self.enableRecordingLight = false
        }
        else {
            self.enableRecordingLight = true
        }
        self.metronomeTempoAtRecordingStart = metronomeTempoAtRecordingStart
    }
    
    func endMetronomePrefix() {
        DispatchQueue.main.async {
            self.enableRecordingLight = true
        }
    }
    
    func makeTap()  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let date = Date()
        self.tapTimes.append(date.timeIntervalSince1970)
        //audioPlayer.play() Audio Player starts the tick too slowly for fast tempos and short value note and therefore throws of the tapping
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }

    func stopRecording(score:Score) -> ([Double]) {
        self.tapTimes.append(Date().timeIntervalSince1970) // record value of last tap made
        self.tappedValues = []
        var last:Double? = nil
        for t in tapTimes {
            var diff = 0.0
            if last != nil {
                diff = (t - last!)
            }
            if last != nil {
                self.tappedValues.append(diff)
            }
            last = t
        }
        return self.tappedValues
    }

    //Return the standard note value for a millisecond duration given the tempo input
    func roundNoteValueToStandardValue(inValue:Double, tempo:Int) -> Double? {
        let inValueAtTempo = (inValue * Double(tempo)) / 60.0
        if inValueAtTempo < 0.3 {
            return nil
        }
        if inValueAtTempo < 0.75 {
            return 0.5
        }
        if inValueAtTempo < 1.5 {
            return 1.0
        }
        if inValueAtTempo < 2.5 {
            return 2.0
        }
        if inValueAtTempo < 3.5 {
            return 3.0
        }
        return 4.0
    }
    
    //Make a score of notes and barlines from the tap intervals
    func makeScore(questionScore:Score, questionTempo:Int, tapValues: [Double]) -> Score {
        let outputScore = Score(timeSignature: questionScore.timeSignature, linesPerStaff: 1)
        let staff = Staff(score: outputScore, type: .treble, staffNum: 0, linesInStaff: 1)
        outputScore.setStaff(num: 0, staff: staff)
        
        let lastQuestionTimeslice = questionScore.getLastTimeSlice()
        var lastQuestionNote:Note?
        if let ts = lastQuestionTimeslice {
            if ts.getTimeSliceNotes().count > 0 {
                lastQuestionNote = ts.getTimeSliceNotes()[0]
            }
        }
        
        var totalValue = 0.0
        let questionScoreTimeSlices = questionScore.getAllTimeSlices()
        var questionIdx = 0
        var isAlignedWithQuestion = true
        
        for i in 0..<tapValues.count {
            let n = tapValues[i]
            let tappedValue = roundNoteValueToStandardValue(inValue: n, tempo: questionTempo)
            if var tappedValue = tappedValue {
                if totalValue >= Double(questionScore.timeSignature.top) {
                    outputScore.addBarLine()
                    totalValue = 0.0
                }
                //
                //var value = tappedValue
                if i == tapValues.count - 1 {
                    //The last tap value is when the student endeed the recording and they may have delayed the stop recording
                    //So instead of the tapped value, let the last note value be the last question note value
                    if lastQuestionNote != nil {
                        if tappedValue > lastQuestionNote!.getValue(){
                            //the student delayed the end of recording
                            tappedValue = lastQuestionNote!.getValue()
                        }
                    }
                }
                if isAlignedWithQuestion {
                    //The user may have tapped say 2 beats but the question has a quaver and a rest
                    //So express the user's tap as a quaver and rest so that their staff view looks like the question view
                    var totalQuestionValue = 0.0
                    while totalQuestionValue < tappedValue {
                        if questionIdx >= questionScoreTimeSlices.count {
                            break
                        }
                        let questionTimeSlice = questionScoreTimeSlices[questionIdx]
                        let entry = questionTimeSlice.entries[0]
                        if totalQuestionValue > 0 && !(entry is Rest) {
                            break
                        }
                        let timeSlice = outputScore.addTimeSlice()
                        if totalQuestionValue == 0 {
                            let note:Note
                            if entry.getValue() > tappedValue {
                                isAlignedWithQuestion = false
                                note = Note(num: 0, value: tappedValue, staffNum: 0)
                            }
                            else {
                                note = Note(num: 0, value: entry.getValue(), staffNum: 0)
                            }
                            note.isOnlyRhythmNote = true
                            timeSlice.addNote(n: note)
                        }
                        else {
                            let rest = Rest(value: entry.getValue(), staffNum: 0)
                            timeSlice.addRest(rest: rest)
                        }
                        totalQuestionValue += entry.getValue()
                        questionIdx += 1
                     }
                }
                else {
                    let timeSlice = outputScore.addTimeSlice()
                    let note = Note(num: 0, value: tappedValue, staffNum: 0)
                    note.isOnlyRhythmNote = true
                    timeSlice.addNote(n: note)
                }
                totalValue += tappedValue
            }
        }
//        for ts in outputScore.getAllTimeSlices() {
//            print("========>", ts.entries[0].getValue(), type(of: ts))
//        }
        return outputScore
    }
        
    //From the recording of the first tick, calculate the tempo the rhythm was tapped at
    func getTempoFromRecordingStart(tapValues:[Double], questionScore: Score) -> Int {
        let scoreTimeSlices = questionScore.getAllTimeSlices()
        let firstNoteValue = scoreTimeSlices[0].getTimeSliceEntries()[0].getValue()
        if self.tappedValues.count == 0 {
            return 60
        }
        //let firstTapValue = self.tapValues1[0]
        let firstTapValue = tapValues[0]
        let tempo = (firstNoteValue / firstTapValue) * 60.0
        return Int(tempo)
    }
    
    //return the tempo of the students recording
    func getRecordedTempo(questionScore:Score) -> Int {
        let tempo = getTempoFromRecordingStart(tapValues: self.tappedValues, questionScore: questionScore)
        return tempo
    }
    
    //Analyse the user's tapped rhythm and return a score representing the ticks they ticked
    func analyseRhythm(timeSignatue:TimeSignature, questionScore:Score, tapValues:[Double]) -> Score {
        let recordedTempo = getTempoFromRecordingStart(tapValues: tapValues, questionScore: questionScore)
        let outScore = self.makeScore(questionScore: questionScore, questionTempo: recordedTempo, tapValues: tapValues) //, tapValues: self.tapValues1)
        outScore.recordedTempo = recordedTempo
        return outScore
    }
      
}

