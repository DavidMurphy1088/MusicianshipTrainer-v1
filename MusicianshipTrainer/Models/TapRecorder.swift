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

//    //Return the standard note value for a millisecond duration given the tempo input
//    func roundNoteValueToStandardValueOld(inValue:Double, tempo:Int) -> Double? {
//        let inValueAtTempo = (inValue * Double(tempo)) / 60.0
//        if inValueAtTempo < 0.3 {
//            return nil
//        }
//        if inValueAtTempo < 0.75 {
//            return 0.5
//        }
//        if inValueAtTempo < 1.5 {
//            return 1.0
//        }
//        if inValueAtTempo < 2.5 {
//            return 2.0
//        }
//        if inValueAtTempo < 3.5 {
//            return 3.0
//        }
//        return 4.0
//    }
    
    //Return the standard note value for a millisecond duration given the tempo input
    //Handle dooted crotchets
    func roundNoteValueToStandardValue(inValue:Double, tempo:Int) -> Double? {
        let inValueAtTempo = (inValue * Double(tempo)) / 60.0
        if inValueAtTempo < 0.25 {
            return 0.25
        }
        if inValueAtTempo < 0.75 {
            return 0.5
        }
        if inValueAtTempo < 1.25 {
            return 1.0
        }
        if inValueAtTempo < 1.75 {
            return 1.5
        }
        if inValueAtTempo < 2.5 {
            return 2.0
        }
        if inValueAtTempo < 3.5 {
            return 3.0
        }
        return 4.0
    }

    ///Make a playable score of notes from the tap intervals
    func makeScoreFromTaps(questionScore:Score, questionTempo:Int, tapValues: [Double]) -> Score {
        let outputScore = Score(key: questionScore.key, timeSignature: questionScore.timeSignature, linesPerStaff: 1)
        let staff = Staff(score: outputScore, type: .treble, staffNum: 0, linesInStaff: 1)
        outputScore.createStaff(num: 0, staff: staff)
        
        //var questionIdx = 0
        
        ///If the last tapped note has duration > question last note value set that value to the last question note value
        ///(Because we are not measuring how long it took the student to hit stop recording)
        let lastQuestionTimeslice = questionScore.getLastTimeSlice()
        var lastQuestionNote:Note?
        if let ts = lastQuestionTimeslice {
            if ts.getTimeSliceNotes().count > 0 {
                lastQuestionNote = ts.getTimeSliceNotes()[0]
            }
        }

        for i in 0..<tapValues.count {
            let tapDuration = tapValues[i]
            var recordedTapDuration = tapDuration * Double(questionTempo) / 60.0
            let roundedTappedValue = roundNoteValueToStandardValue(inValue: tapDuration, tempo: questionTempo)
            if var tappedValue = roundedTappedValue {

                if i == tapValues.count - 1 {
                    //The last tap value is when the student endeed the recording and they may have delayed the stop recording
                    //So instead of using the tapped value, let the last note value be the last question note value so the rhythm is not marked wrong
                    if lastQuestionNote != nil {
                        if tappedValue > lastQuestionNote!.getValue(){
                            //the student delayed the end of recording
                            tappedValue = lastQuestionNote!.getValue()
                            recordedTapDuration = tappedValue
                        }
                    }
                }
                let timeSlice = outputScore.createTimeSlice()
                let note = Note(timeSlice:timeSlice, num: 0, value: tappedValue, staffNum: 0)
                note.setIsOnlyRhythm(way: true)
                timeSlice.tapDuration = recordedTapDuration
                timeSlice.addNote(n: note)
            }
        }
        return outputScore
    }
        
    //From the recording of the first tick, calculate the tempo the rhythm was tapped at
    func getTempoFromRecordingStart(tapValues:[Double], questionScore: Score) -> Int {
        let scoreTimeSlices = questionScore.getAllTimeSlices()
        if scoreTimeSlices.count == 0 {
            return 60
        }
        var firstScoreValue:Double
        if scoreTimeSlices[0].getTimeSliceNotes().count == 0 {
            ///first entry is a rest
            firstScoreValue = scoreTimeSlices[0].getTimeSliceEntries()[0].getValue()
        }
        else {
            firstScoreValue = scoreTimeSlices[0].getTimeSliceNotes()[0].getValue()
        }
        
        for i in 1..<scoreTimeSlices.count {
            let entries = scoreTimeSlices[i].getTimeSliceEntries()
            if entries.count > 0 {
                let entry = entries[0]
                if entry is Note {
                    break
                }
                else {
                    if entry is Rest {
                        firstScoreValue += entry.getValue()
                    }
                }
            }
        }
        //if self.tappedValues.count == 0 
        if tapValues.count == 0 {
            return 60
        }
        //let firstTapValue = self.tapValues1[0]
        let firstTapValue = tapValues[0]
        let tempo = (firstScoreValue / firstTapValue) * 60.0
        return Int(tempo)
    }
    
    //return the tempo of the students recording
    func getRecordedTempo(questionScore:Score) -> Int {
        let tempo = getTempoFromRecordingStart(tapValues: self.tappedValues, questionScore: questionScore)
        return tempo
    }
    
    //Read the user's tapped rhythm and return a score representing the ticks they ticked
    func getTappedAsAScore(timeSignatue:TimeSignature, questionScore:Score, tapValues:[Double]) -> Score {
        let recordedTempo = getTempoFromRecordingStart(tapValues: tapValues, questionScore: questionScore)
        //let recordedTempo = 60
        ///G3,2,43 let tapValues = [0.5,0.5,1.5,0.5,   1.0,2.0,   0.5,0.5, 1, 3, 2]
        ///
        //let tapValues:[Double] = [1,1,1,1,1,1]
        let tappedScore = self.makeScoreFromTaps(questionScore: questionScore, questionTempo: recordedTempo, tapValues: tapValues) //, tapValues: self.tapValues1)
        tappedScore.tempo = recordedTempo
        return tappedScore
    }
      
}

