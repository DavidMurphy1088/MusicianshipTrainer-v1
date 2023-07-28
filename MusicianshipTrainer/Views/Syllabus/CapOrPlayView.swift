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
                    audioRecorder.playRecording()
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
    @ObservedObject var answer:Answer
    let testMode:TestMode
    var questionType:QuestionType

    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject private var metronome:Metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "ClapOrPlayPresentView init @ObservedObject")
    @State var tappingView:TappingView? = nil
    @State private var helpPopup = false
    @State var isTapping = false
    @State var rhythmHeard:Bool
    //let exampleData = ExampleData.shared
    //var onRefresh: (() -> Void)? = nil
    let questionTempo = 90
    
//    static func onRefresh() {
//    }
//    //static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode) -> QuestionPartProtocol
//    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType) -> QuestionPartProtocol {
//        return ClapOrPlayPresentView(contentSection: contentSection, score:score, answer: answer, testMode:testMode, questionType: questionType, refresh: onRefresh)
//    }
    
    init(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType, refresh_unused:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.answer = answer
        self.questionType = questionType
        self.testMode = testMode
        self.questionType = questionType
        self.rhythmHeard = false
    }
    
    func initScore() {
        let exampleData = contentSection.parseData()
        self.rhythmHeard = self.questionType == .rhythmVisualClap ? true : false
        var staff:Staff?
        
        if let entries = exampleData {
            for entry in entries {
                if entry is KeySignature {
                    let keySignature = entry as! KeySignature
                    score.setKey(key: Key(type: .major, keySig: keySignature))
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

//        case :
//            result += "tap your rhythm on the drum. Remember to tap rather than hold your finger firmly down."
            
        default:
            result = ""
        }
        return result
    }
    
    func getStudentScoreWithTempo() -> Score {
        let rhythmAnalysis = tapRecorder.analyseRhythm(timeSignatue: score.timeSignature, questionScore: score)
        return rhythmAnalysis
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        var practiceText = "You can adjust the metronome to hear the given \(lname) at varying tempi."
        if questionType == .melodyPlay {
            practiceText += " You can also tap tap the picture of the metronome to practise along with the tick."
        }
        return practiceText
    }
    
    var body: AnyView {
        AnyView(
            VStack  {
                VStack {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        if questionType == .melodyPlay || questionType == .rhythmEchoClap {
                            ToolsView(score: score, helpMetronome: helpMetronome())
                        }
                        else {
                            Text(" ")
                        }
                    }

                    if questionType == .rhythmVisualClap || questionType == .melodyPlay {
                        ScoreSpacerView()
                        ScoreView(score: score)
                            .padding()
                        ScoreSpacerView()
                    }
                    
                    if answer.state != .recording {
                        let uname = questionType == .melodyPlay ? "Melody" : "Rhythm"
                        PlayRecordingView(buttonLabel: "Hear The Given \(uname)",
                                          score: score,
                                          metronome: metronome,
                                          onDone: {rhythmHeard = true})
                        
                    }

                    VStack {
                        if answer.state != .recording {
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
                                answer.setState(ctx1: "clap", .recording)
                                
                                metronome.stopTicking()
                                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                                    self.isTapping = true
                                    tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                                } else {
                                    audioRecorder.startRecording(outputFileName: contentSection.name)
                                }
                            }) {
                                Text(answer.state == .notEverAnswered ? "Start Recording" : "Redo Recording")
                                    .foregroundColor(.white).padding().background(rhythmHeard || questionType == .melodyPlay ? Color.blue : Color.gray).cornerRadius(UIGlobals.buttonCornerRadius).padding()
                                    .onAppear() {
                                        tappingView = TappingView(isRecording: $isTapping, tapRecorder: tapRecorder)
                                    }
                            }
                            .disabled(!rhythmHeard && questionType != .melodyPlay)
                        }
                                                    
                        if answer.state == .recording {
                            Button(action: {
                                answer.setState(ctx1: "clap", .recorded)
                                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                                    self.isTapping = false
                                    self.tapRecorder.stopRecording()
                                    isTapping = false
                                }
                                else {
                                    audioRecorder.stopRecording()
                                }
                            }) {
                                Text("Stop Recording")
                                    .defaultStyle()
                            }//.padding()
                        }

                        if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                            VStack {
                                tappingView
                            }
                            .padding()
                        }

                        if answer.state == .recorded {
                            if testMode.mode == .practice || answer.state == .notEverAnswered {
                                PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                                  score: questionType == .melodyPlay ? nil : getStudentScoreWithTempo(),
                                                  metronome: self.metronome,
                                                  onStart: ({
                                    if questionType != .melodyPlay {
                                        if let recordedTempo = getStudentScoreWithTempo().recordedTempo {
                                            metronome.setTempo(tempo: recordedTempo, context:"start hear student")
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
                                answer.setState(ctx1: "clap", .submittedAnswer)
                                score.setHiddenStaff(num: 1, isHidden: false)
                            }) {
                                //Stop the UI jumping around when answer.state changes state
                                Text(answer.state == .recorded ? "\(testMode.mode == .exam ? "Submit" : "Check") Your Answer" : "")
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
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject var answer:Answer
    
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared
    
    @State var playingCorrect = false
    @State var playingStudent = false
    @State var speechEnabled = false
    @State var tappingScore:Score?
    @ObservedObject var answerMetronome:Metronome
    @State var answerWasCorrect:Bool = false
    @ObservedObject var score:Score
    private var questionType:QuestionType
    let questionTempo = 90
    let testMode:TestMode
    var onRefresh: (() -> Void)? = nil
    
//    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType) -> QuestionPartProtocol {
//        return ClapOrPlayAnswerView(contentSection:contentSection, score:score, answer: answer, testMode:testMode, questionType: questionType)
//    }
    
    init(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.answer = answer
        self.score = score
        self.testMode = testMode
        self.questionType = questionType
        self.answerMetronome = Metronome.getMetronomeWithCurrentSettings(ctx:"ClapOrPlayAnswerView")
        print(Metronome.getMetronomeWithCurrentSettings(ctx: "TEST").tempo)
        answerMetronome.setSpeechEnabled(enabled: self.speechEnabled)
        self.onRefresh = refresh
    }
    
    func analyseStudentRhythm() {
        let rhythmAnalysis = tapRecorder.analyseRhythm(timeSignatue: score.timeSignature, questionScore: score)
        self.tappingScore = rhythmAnalysis
        if let tappingScore = tappingScore {
            let errorsExist = score.markupStudentScore(questionTempo: self.questionTempo, recordedTempo: 0, metronomeTempo: 0,
                                                       metronomeTempoAtStartRecording: tapRecorder.metronomeTempoAtRecordingStart ?? 0,
                                                       scoreToCompare: tappingScore, allowTempoVariation: questionType != .rhythmEchoClap)
            self.answerWasCorrect = !errorsExist
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
                                      metronome: answerMetronome)
                    
                    if questionType == .melodyPlay {
                        PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                          score: nil,
                                          metronome: answerMetronome)
                    }
                    else {
                        if let tappingScore = self.tappingScore {
                            PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                              score: tappingScore,
                                              metronome: answerMetronome)
                        }
                    }
                    
                    Button(action: {
                        if let refresh = self.onRefresh {
                            refresh()
                        }
                    }) {
                        Text("Try Again")
                            .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
                    }
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
    let id = UUID()
    let questionType:QuestionType
    let contentSection:ContentSection
    let nextNavigationView:NextNavigationView
    let testMode:TestMode
    
    @State var refresh:Bool = false
    
    //WARNING - Making Score a @STATE makes instance #1 of this struct pass its Score to instance #2
    var score:Score
    @ObservedObject var logger = Logger.logger
    @ObservedObject var answer: Answer
   
    func onRefresh() {
        self.answer.setState(ctx1: "clap", .notEverAnswered)
        DispatchQueue.main.async {
            self.refresh.toggle()
        }
    }

    init(questionType:QuestionType, contentSection:ContentSection, testMode:TestMode, nextNavigationView:NextNavigationView, answer:Answer) {
        self.questionType = questionType
        self.contentSection = contentSection
        self.nextNavigationView = nextNavigationView
        self.testMode = testMode
        self.answer = answer
        self.score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
     }
    
    func getNavigationDescription() -> String {
        if testMode.mode == .exam {
            if nextNavigationView.hasNextPage() {
                return "Go to the Next Test Question"
            }
            else {
                return "End of Test"
            }
        }
        else {
            return "Go to the Next Example"
        }
    }
 
    var body: some View {
        VStack {
            //Text("=============== \(testMode.mode == .exam ? "EXAM" : "PRACTICE") SUBMITTED STATE:\(answer.state == .submittedAnswer ? "YES" : "NOT")")
            if answer.state != .submittedAnswer {
                ClapOrPlayPresentView(
                    contentSection: contentSection,
                    score: score,
                    answer: answer,
                    testMode:testMode,
                    questionType: questionType)

            }
            else {
                if testMode.mode == .practice {
                    ClapOrPlayAnswerView(contentSection: contentSection,
                                         score: score,
                                         answer: answer,
                                         testMode:testMode,
                                         questionType: questionType,
                                         refresh: onRefresh)
                }
            }
            if answer.state == .submittedAnswer {
                VStack {
                    Button(action: {
                        nextNavigationView.navigateNext()
                    }) {
                        Text(self.getNavigationDescription()).defaultStyle()
                    }
                }
                .padding()
            }
        }
        .background(UIGlobals.colorBackground)
        .onAppear {
            self.answer.setState(ctx1: "clap", .notEverAnswered)
        }
    }

}
