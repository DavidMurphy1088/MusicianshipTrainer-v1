import SwiftUI

enum QuestionType {
    //intervals
    case intervalVisual
    case intervalAural
    
    //rhythms
    case rhythmVisualClap
    case melodyPlay
    case rhythmEchoClap
    
    case none
}

struct PracticeToolView: View {
    var text:String
    var body: some View {
        HStack {
            Text("Practice Tool:")//.padding()
            Text(text)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        //.background(UIGlobals.backgroundColorLighter)
        .background(UIGlobals.colorInstructions)
        .padding()
    }
}

struct PlayRecordingView: View {
    var buttonLabel:String
    @State var score:Score?
    @State var metronome:Metronome
    let fileName:String
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @State private var playingScore:Bool = false
    var onStart: (()->Void)?
    var onDone: (()->Void)?
    

    var body: some View {
        VStack {
            Button(action: {
                if let onStart = onStart {
                    onStart()
                }
                if let score = score {
                    metronome.playScore(score: score, onDone: {
                        playingScore = false
                        if let onDone = onDone {
                            onDone()
                        }
                    })
                    playingScore = true
                }
                else {
                    audioRecorder.playRecording(fileName: fileName)
                }
            }) {
                if playingScore {
                    Button(action: {
                        playingScore = false
                        metronome.stopPlayingScore()
                    }) {
                        Text("Stop Playing")
                            .defaultStyle()
                        Image(systemName: "stop.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }
                else {
                    Text(self.buttonLabel)
                        .defaultStyle()
                }
            }
            .padding()
        }
    }
}

struct ClapOrPlayPresentView: View {
    let contentSection:ContentSection
    @ObservedObject var score:Score
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject private var metronome:Metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "ClapOrPlayPresentView init @ObservedObject")
    @Binding var answerState:AnswerState
    @Binding var answer:Answer

    @State var tappingView:TappingView? = nil
    @State private var helpPopup = false
    @State var isTapping = false
    @State var rhythmHeard:Bool
    var questionType:QuestionType

    let questionTempo = 90
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh_unused:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        self.questionType = questionType
        self.rhythmHeard = false
        _answerState = answerState
        _answer = answer
    }
    
    func initScore() {
        let exampleData = contentSection.parseData()
        self.rhythmHeard = self.questionType == .rhythmVisualClap ? true : false
        var staff:Staff?
        
        if let entries = exampleData {
            for entry in entries {
                if entry is KeySignature {
                    let keySignature = entry as! KeySignature
                    score.key = Key(type: .major, keySig: keySignature)
                    //score.setKey(key: )
                }
                if entry is TimeSignature {
                    let ts = entry as! TimeSignature
                    score.timeSignature = ts
                }
                if entry is StaffCharacteristics {
                    staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: (questionType == .rhythmVisualClap || questionType == .rhythmEchoClap) ? 1 : 5)
                    score.setStaff(num: 0, staff: staff!)
                }
                if entry is Note {
                    let timeSlice = score.addTimeSlice()
                    let note = entry as! Note
                    note.staffNum = 0
                    note.setIsOnlyRhythm(way: questionType == .rhythmVisualClap || questionType == .rhythmEchoClap ? true : false)
                    timeSlice.addNote(n: note)
                }
                if entry is BarLine {
                    score.addBarLine()
                }
            }
        }
        if staff == nil {
            //TODO remove when conversion to cloud content is done
            staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: (questionType == .rhythmVisualClap || questionType == .rhythmEchoClap) ? 1 : 5)
            score.setStaff(num: 0, staff: staff!)
        }
        if questionType == .melodyPlay {
            if let timeSlice = score.getLastTimeSlice() {
                timeSlice.addTonicChord()
                timeSlice.setTags(high: score.key.keySig.accidentalCount > 0 ? "G" : "C", low: "I")
            }
            let bstaff = Staff(score: score, type: .bass, staffNum: 1, linesInStaff: questionType == .rhythmVisualClap ? 1 : 5)
            bstaff.isHidden = true
            score.setStaff(num: 1, staff: bstaff)
            //score.hiddenStaffNo = 1
        }
    }

    func getInstruction(mode:QuestionType) -> String {
        var result = ""
        switch mode {
            
        case .rhythmVisualClap, .rhythmEchoClap:
            //result += "you will be counted in for one full bar. Then tap your rhythm on the drum."
            result += "Listen to the given rhythm then press Start Recording. Tap your rhythm on the drum below."
            result += "\n\nFor a clear result, you should tap and then immediately release your finger (like a staccato motion), rather than holding it down on the device."
            result += "\n\nWhen you have finished, stop the recording."
            result += "\n\nIf you tap the rhythm incorrectly, you will be able to hear your rhythm and the given rhythm at crotchet = 90 on the next page."

        case .melodyPlay:
            result += "Press Start Recording then "
            result += "play the melody and the final chord."
            //result += "\n\nWhen you have finished, stop the recording."
            result += " When you have finished, stop the recording."

        default:
            result = ""
        }
        return result
    }
    
    func getStudentRecordedScoreWithTempo() -> Score? {
        if let values = self.answer.values {
            let rhythmAnalysisScore = tapRecorder.analyseRhythm(timeSignatue: score.timeSignature, questionScore: score, tapValues: values)
            return rhythmAnalysisScore
        }
        else {
            return nil
        }
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        var practiceText = "You can adjust the metronome to hear the given \(lname) at varying tempi."
        if questionType == .melodyPlay {
            practiceText += " You can also tap tap the picture of the metronome to practise along with the tick."
        }
        return practiceText
    }
    
    func rhythmIsCorrect() -> Bool {
        guard let tapValues = answer.values else {
            return false
        }
        let tappingScore = tapRecorder.analyseRhythm(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        let errorsExist = score.markupStudentScore(questionTempo: self.questionTempo,
                                                   //recordedTempo: 0,
                                                   metronomeTempoAtStartRecording: tapRecorder.metronomeTempoAtRecordingStart ?? 0,
                                                   scoreToCompare: tappingScore, allowTempoVariation: questionType != .rhythmEchoClap)
        //print("============Rhythm Correct Errors:", errorsExist, "Tempo", self.questionTempo, "tap Metro tempo", tapRecorder.metronomeTempoAtRecordingStart ?? 0)
        return !errorsExist
    }
         
    func replayRecordingAllowed() -> Bool {
        guard let parent = contentSection.parent else {
            return true
        }
        if parent.isExamTypeContentSection() {
            //|| answerState == .notEverAnswered {
            ///Only allowed when section is exam but student is in exam review mode
            if contentSection.answer111 == nil {
                return false
            }
            else {
                return true
            }
        }
        return true
    }
    
    func isTakingExam() -> Bool {
        guard let parent = contentSection.parent else {
            return false
        }
        if parent.isExamTypeContentSection() && contentSection.answer111 == nil {
            return true
        }
        else {
            return false
        }
    }

    var body: AnyView {
        AnyView(
            VStack  {
                VStack {
                    if !self.isTakingExam() {
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            if questionType == .melodyPlay || questionType == .rhythmEchoClap {
                                ToolsView(score: score, helpMetronome: helpMetronome())
                            }
                            else {
                                Text(" ")
                            }
                        }
                    }

                    if questionType == .rhythmVisualClap || questionType == .melodyPlay {
                        ScoreSpacerView()
                        ScoreView(score: score)
                            .padding()
                        ScoreSpacerView()
                    }
                    
                    if answerState != .recording {
                        let uname = questionType == .melodyPlay ? "Melody" : "Rhythm"
                        PlayRecordingView(buttonLabel: "Hear The Given \(uname)",
                                          score: score,
                                          metronome: metronome,
                                          fileName: contentSection.name,
                                          onDone: {rhythmHeard = true})
                        
                    }

                    VStack {
                        if answerState != .recording {
                            VStack {
                                Text(self.getInstruction(mode: self.questionType))
                                    .lineLimit(nil)
                                    .padding()
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                            )
                            //.background(UIGlobals.backgroundColorLighter)
                            //.background(UIGlobals.backgroundColorHiliteBox)

                            Button(action: {
                                //contentSection.setAnswerState(ctx: "clap", .recording)
                                answerState = .recording
                                metronome.stopTicking()
                                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                                    self.isTapping = true
                                    tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                                } else {
                                    audioRecorder.startRecording(fileName: contentSection.name)
                                }
                            }) {
                                Text(answerState == .notEverAnswered ? "Start Recording" : "Redo Recording")
                                    .foregroundColor(.white).padding().background(rhythmHeard || questionType == .melodyPlay ? Color.blue : Color.gray).cornerRadius(UIGlobals.buttonCornerRadius).padding()
                                    .onAppear() {
                                        tappingView = TappingView(isRecording: $isTapping, tapRecorder: tapRecorder)
                                    }
                            }
                            .disabled(!rhythmHeard && questionType != .melodyPlay)
                        }
                                                    
                        if answerState == .recording {
                            Button(action: {
                                //contentSection.setAnswerState(ctx: "clap", .recorded)
                                answerState = .recorded
                                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                                    self.isTapping = false
                                    answer.values = self.tapRecorder.stopRecording(score:score)
                                    isTapping = false
                                }
                                else {
                                    audioRecorder.stopRecording()
                                    answer.recordedData = self.audioRecorder.getRecordedAudio(fileName: contentSection.name)
                                }
                            }) {
                                Text("Stop Recording").defaultStyle()
                            }
                        }

                        if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                            VStack {
                                tappingView
                            }
                            .padding()
                        }

                        if answerState == .recorded {
                            
                            if replayRecordingAllowed() {
                                PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                                  score: questionType == .melodyPlay ? nil : getStudentRecordedScoreWithTempo(),
                                                  metronome: self.metronome,
                                                  fileName: contentSection.name,
                                                  onStart: ({
                                    if questionType != .melodyPlay {
                                        if let recordedScore = getStudentRecordedScoreWithTempo() {
                                            if let recordedtempo = recordedScore.recordedTempo {
                                                metronome.setTempo(tempo: recordedtempo, context:"start hear student")
                                            }
                                        }
                                    }
                                }),
                                onDone: ({
                                    //recording was played at the student's tempo and now reset metronome
                                    metronome.setTempo(tempo: self.questionTempo, context: "end hear student")
                                })
                                )
                            }
                            
                            Button(action: {
                                //contentSection.setAnswerState(ctx: "clap", .submittedAnswer)
//                                if let parent = contentSection.parent {
//                                    if parent.isExamTypeContentSection() {
//                                        contentSection.answer111 = answer
//                                    }
//                                }
                                answerState = .submittedAnswer
                                if questionType == .melodyPlay {
                                    answer.correct = true
                                }
                                else {
                                    answer.correct = rhythmIsCorrect()
                                }
                                score.setHiddenStaff(num: 1, isHidden: false)
                            }) {
                                //Stop the UI jumping around when answer.state changes state
                                Text(answerState == .recorded ? "\(self.isTakingExam() ? "Submit" : "Check") Your Answer" : "")
                                    .defaultStyle()
                            }
                            .padding()
                        }
                    }
                    Spacer() //Keep - required to align the page from the top
                    //Text(audioRecorder.status).padding()
//                    if logger.status.count > 0 {
//                        Text(logger.status).font(logger.isError ? .title3 : .body).foregroundColor(logger.isError ? .red : .gray)
//                    }
                }
                .onAppear() {
                    self.initScore()
                    score.setHiddenStaff(num: 1, isHidden: true)
                    metronome.setTempo(tempo: 90, context: "View init")
                    if questionType == .rhythmEchoClap || questionType == .melodyPlay {
                        metronome.setAllowTempoChange(allow: true)
                    }
                    else {
                        metronome.setAllowTempoChange(allow: false)
                    }
                }
            }
            .font(.system(size: UIDevice.current.userInterfaceIdiom == .phone ? UIFont.systemFontSize : UIFont.systemFontSize * 1.6))
        )
    }
}

struct ClapOrPlayAnswerView: View { //}, QuestionPartProtocol {
    let contentSection:ContentSection
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject var answerMetronome:Metronome

    @State var playingCorrect = false
    @State var playingStudent = false
    @State var speechEnabled = false
    @State var tappingScore:Score?
    
    private var score:Score
    private var questionType:QuestionType
    private var answer:Answer
    
    let questionTempo = 90
    var onRefresh: (() -> Void)? = nil
    
    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        self.answerMetronome = Metronome.getMetronomeWithCurrentSettings(ctx:"ClapOrPlayAnswerView")
        //print(Metronome.getMetronomeWithCurrentSettings(ctx: "TEST").tempo)
        self.onRefresh = refresh
        self.answer = answer
        answerMetronome.setSpeechEnabled(enabled: self.speechEnabled)
    }
    
    func analyseStudentRhythm() {
        guard let tapValues = answer.values else {
            return
        }
        let rhythmAnalysis = tapRecorder.analyseRhythm(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        self.tappingScore = rhythmAnalysis
        if let tappingScore = tappingScore {
            let errorsExist = score.markupStudentScore(questionTempo: self.questionTempo,
                                                       //recordedTempo: 0, metronomeTempo: 0,
                                                       metronomeTempoAtStartRecording: tapRecorder.metronomeTempoAtRecordingStart ?? 0,
                                                       scoreToCompare: tappingScore, allowTempoVariation: questionType != .rhythmEchoClap)
            //self.answerWasCorrect1 = !errorsExist
            //print("============analyseStudentRhythm errors:", errorsExist, "Tempo", self.questionTempo, "tap Metro tempo", tapRecorder.metronomeTempoAtRecordingStart ?? 0)
            if errorsExist {
                //self.metronome.setTempo(tempo: self.questionTempo, context: "Analyse Student - failed")
                self.answerMetronome.setAllowTempoChange(allow: false)
                self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")
            }
            else {
                if let recordedTempo = rhythmAnalysis.recordedTempo {
                    self.answerMetronome.setTempo(tempo: recordedTempo, context: "Analyse Student - passed", allowBeyondLimits: true)
                }
                self.answerMetronome.setAllowTempoChange(allow: true)
            }
            tappingScore.label = "Your Rhythm"
        }
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        var practiceText = "You can adjust the metronome to hear the given \(lname) at varying tempi."
        //if mode == .melodyPlay {
            practiceText += " You can also tap the picture of the metronome to practise along with the tick."
        //}
        return practiceText
    }

    var body: AnyView {
        AnyView(
            VStack {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    if questionType != .melodyPlay {
                        ToolsView(score: score, helpMetronome: helpMetronome())
                    }
                    else {
                        Text(" ")
                    }
                }
                ScoreSpacerView()
                if questionType == .melodyPlay {
                    ScoreSpacerView()
                }
                ScoreView(score: score).padding()
                ScoreSpacerView()
                if questionType == .melodyPlay {
                    ScoreSpacerView()
                }
                if let tappingScore = self.tappingScore {
                    Text(" ")
                    ScoreSpacerView()
                    ScoreView(score: tappingScore).padding()
                    ScoreSpacerView()
                }
                
                VStack {
                    
                    PlayRecordingView(buttonLabel: "Hear The Given \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                      score: score,
                                      metronome: answerMetronome,
                                      fileName: contentSection.name)
                    
                    if questionType == .melodyPlay {
                        PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                          score: nil,
                                          metronome: answerMetronome,
                                          fileName: contentSection.name)
                    }
                    else {
                        if let tappingScore = self.tappingScore {
                            PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                              score: tappingScore,
                                              metronome: answerMetronome,
                                              fileName: contentSection.name)
                        }
                    }
                    
//                    Button(action: {
//                        if let refresh = self.onRefresh {
//                            refresh()
//                        }
//                    }) {
//                        Text("Try Again")
//                            .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
//                    }
                    Spacer() //Keep - required to align the page from the top
                }

                //Text(audioRecorder.status).padding()
    //                    if logger.status.count > 0 {
    //                        Text(logger.status).font(logger.isError ? .title3 : .body).foregroundColor(logger.isError ? .red : .gray)
    //                    }
            }
            .onAppear() {
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    analyseStudentRhythm()
                }
                else {
                    answerMetronome.setTempo(tempo: questionTempo, context: "AnswerMode::OnAppear")
                }
                score.setHiddenStaff(num: 1, isHidden: false)
            }
            .onDisappear() {
                score.clearTaggs() //clear tags from any previous attempt
            }
        )
    }
}

struct ClapOrPlayView: View {
    let contentSection: ContentSection
    @ObservedObject var logger = Logger.logger

    @Binding var answerState:AnswerState
    @Binding var answer:Answer

    @State var refresh:Bool = false

    let id = UUID()
    let questionType:QuestionType
    
    @State var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
   
    func onRefresh() {
        DispatchQueue.main.async {
            self.refresh.toggle()
        }
    }

    init(questionType:QuestionType, contentSection:ContentSection, answerState:Binding<AnswerState>, answer:Binding<Answer>) {
        self.questionType = questionType
        self.contentSection = contentSection
        _answerState = answerState
        _answer = answer
    }
    
    func shouldShowAnswer() -> Bool {
        if let parent = contentSection.parent {
            if parent.isExamTypeContentSection() {
                if answerState  == .submittedAnswer {
                    //Only show answer for exam questions in exam review mode
                    if contentSection.answer111 == nil {
                        return false
                    }
                    else {
                        //print("====>show answer", parent.name, contentSection.name, contentSection.answer111?.correct)
                        return true
                    }
                } else {
                    return false
                }
            }
            return true
        }
        else {
            return true
        }
    }

     var body: some View {
        VStack {
            if answerState  != .submittedAnswer {
                ClapOrPlayPresentView(
                    contentSection: contentSection,
                    score: score,
                    answerState: $answerState,
                    answer: $answer,
                    questionType: questionType)

            }
            else {
                if shouldShowAnswer() {
                    ClapOrPlayAnswerView(contentSection: contentSection,
                                         score: score,
                                         answer: answer,
                                         questionType: questionType,
                                         refresh: onRefresh)
                }
            }

        }
        .background(UIGlobals.colorBackground)
        .onAppear {
        }
    }

}
