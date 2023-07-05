import SwiftUI
import CoreData
import AVFoundation

class TapRecorder : NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate, ObservableObject {
    static let shared = TapRecorder()
    var tapTimes:[Double] = []
    var tapValues:[Double] = []
    @Published var status:String = ""
    @Published var enableRecordingLight = false
    var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "Tap Recorder init")
    
    func setStatus(_ msg:String) {
        DispatchQueue.main.async {
            self.status = msg
        }
    }
    
    func startRecording(metronomeLeadIn:Bool)  {
        self.tapValues = []
        self.tapTimes = []
        if metronomeLeadIn {
            self.enableRecordingLight = false
            //metronome.startTicking(numberOfTicks: timeSignature.top * 2, onDone: endMetronomePrefix)
        }
        else {
            self.enableRecordingLight = true
        }
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

    func stopRecording() {
        self.tapTimes.append(Date().timeIntervalSince1970) // record value of last tap made
        tapValues = []
        var last:Double? = nil
        for t in tapTimes {
            var diff = 0.0
            if last != nil {
                diff = (t - last!)
            }
            if last != nil {
                tapValues.append(diff)
            }
            last = t
        }
        //print("TapRecorder::stopRecording times", tapValues.count)
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
    
    //make a score of notes and barlines from the tap intervals
    func makeScore(questionScore:Score, questionTempo:Int) -> Score {
        let outputScore = Score(timeSignature: questionScore.timeSignature, linesPerStaff: 1)
        let staff = Staff(score: outputScore, type: .treble, staffNum: 0, linesInStaff: 1)
        outputScore.setStaff(num: 0, staff: staff)
        var ctr = 0
        
        let lastQuestionTimeslice = questionScore.getLastTimeSlice()
        var lastQuestionNote:Note?
        if let ts = lastQuestionTimeslice {
            if ts.notes.count > 0 {
                lastQuestionNote = ts.notes[0]
            }
        }
        
        var totalValue = 0.0
        
        for i in 0..<self.tapValues.count {
            let n = self.tapValues[i]
            let noteValue = roundNoteValueToStandardValue(inValue: n, tempo: questionTempo)
            if let noteValue = noteValue {
                if totalValue >= Double(questionScore.timeSignature.top) {
                    outputScore.addBarLine()
                    totalValue = 0.0
                }
                let timeSlice = outputScore.addTimeSlice()

                var value = noteValue
                if i == self.tapValues.count - 1 {
//                    //The last tap value is when the studnet endeded the recording. So instead, let the last note value be the last question note value
                    if lastQuestionNote != nil {
                        if value > lastQuestionNote!.getValue(){
                            //the student delayed the end of recording
                            value = lastQuestionNote!.getValue()
                        }
                    }
                }
                let note = Note(num: 0, value: value)
                note.isOnlyRhythmNote = true
                timeSlice.addNote(n: note)
                totalValue += noteValue
            }
            ctr += 1
        }
        
        return outputScore
    }
        
    //From the recording of the first tick, calculate the tempo the rhythm was tapped at
    func getTempoFromRecordingStart(tapValues:[Double], questionScore: Score) -> Int {
        let scoreTimeSlices = questionScore.getAllTimeSlices()
        let firstNoteValue = scoreTimeSlices[0].notes[0].getValue()
        if self.tapValues.count == 0 {
            return 60
        }
        let firstTapValue = self.tapValues[0]
        let tempo = (firstNoteValue / firstTapValue) * 60.0
        return Int(tempo)
    }
    
    //return the tempo of the students recording
    func getRecordedTempo(questionScore:Score) -> Int {
        let tempo = getTempoFromRecordingStart(tapValues: self.tapValues, questionScore: questionScore)
        return tempo
    }
    
    //Analyse the user's tapped rhythm and return a score representing the ticks they ticked
    func analyseRhythm(timeSignatue:TimeSignature, questionScore:Score) -> Score {
        let recordedTempo = getTempoFromRecordingStart(tapValues: self.tapValues, questionScore: questionScore)
        let outScore = self.makeScore(questionScore: questionScore, questionTempo: recordedTempo)
        outScore.recordedTempo = recordedTempo
        return outScore
    }
      
}

