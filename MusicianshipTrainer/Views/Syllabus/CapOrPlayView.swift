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
                            .defaultButtonStyle()
                        Image(systemName: "stop.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }
                else {
                    Text(self.buttonLabel)
                        .defaultButtonStyle()
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

    @State private var helpPopup = false
    @State var isTapping = false
    @State var rhythmHeard:Bool = false
    @State private var examInstructionsStartedStatus = "Waiting for Instructions..."

    var questionType:QuestionType
    let questionTempo = 90
    let googleAPI = GoogleAPI.shared

    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh_unused:(() -> Void)? = nil) {
        self.contentSection = contentSection
        //self.score = score
        self.questionType = questionType
        _answerState = answerState
        _answer = answer
        self.score = score
        //self.score.debugScore("ClapOrPlayPresentView", withBeam: true)
        if score.staffs.count > 1 {
            self.score.staffs[1].isHidden = true
        }
        self.rhythmHeard = self.questionType == .rhythmVisualClap ? true : false
    }
    
//    func initScore() {
////        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: (questionType == .rhythmVisualClap || questionType == .rhythmEchoClap) ? 1 : 5)
////        self.score.setStaff(num: 0, staff: staff)
//
//    }
    
    func examInstructionsDone(status:RequestStatus) {
    }
    
    func getInstruction(mode:QuestionType, number:Int, grade:Int) -> String? {
        var result = ""
        let bullet = "\u{2022}" + " "
        var linefeed = "\n"
        if !UIDevice.current.orientation.isLandscape {
            linefeed = linefeed + "\n"
        }
        if number == 0 {
            switch mode {
            case .rhythmVisualClap:
                result += "\(bullet)Look through the given rhythm."
                result += "\(linefeed)\(bullet)When you are ready to, press Start Recording."
                result += "\(linefeed)\(bullet)Tap your rhythm on the drum and then press Stop Recording once you have finished."
                
            case .rhythmEchoClap:
                result += "\(bullet)Listen to the given rhythm."
                //result += "\(linefeed)\(bullet)When it has finished you will be able to press Start Recording."
                result += "\(linefeed)\(bullet)Tap your rhythm on the drum that appears and then press Stop Recording once you have finished."

            case .melodyPlay:
                result += "\(bullet)Press Start Recording then "
                result += "play the melody and the final chord."
                result += "\(linefeed)\(bullet)When you have finished, stop the recording."
                
            default:
                result = ""
            }
        }
        if number == 1 {
            switch mode {
            case .rhythmVisualClap:
                result += "\(bullet)Advice: For a clear result, you should tap and then immediately release"
                result += " your finger from the screen, rather than holding it down."
                if grade >= 2 {
                    result += "\n\n\(bullet)For rests, accurately count them but do not touch the screen."
                }
                
            case .rhythmEchoClap:
                result += "\(bullet)Advice: For a clear result, you should tap and then immediately release"
                result += " your finger from the screen, rather than holding it down."
                result += "\n\n\(bullet)If you tap the rhythm incorrectly, you will be able to hear your rhythm attempt and the correct given rhythm at crotchet = 90 on the Answer Page."
                
            default:
                result = ""
            }
        }
        return result.count > 0 ? result : nil
    }
    
    func getStudentTappingAsAScore() -> Score? {
        if let values = self.answer.values {
            let rhythmAnalysisScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: values)
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
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        let fittedScore = score.fitScoreToQuestionScore(tappedScore:tappedScore).0
        if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
            return true
        }
        return false
    }
         
    func instructionView() -> some View {
        VStack {
            if let instruction = self.getInstruction(mode: self.questionType, number: 0, grade: contentSection.getGrade()) {
                Text(instruction)
                    .defaultTextStyle()
                    .padding()
                    .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                    )
                    .padding()
            }
            if let instruction = self.getInstruction(mode: self.questionType, number: 1, grade: contentSection.getGrade()) {
                Text(instruction)
                    .defaultTextStyle()
                    .padding()
                    .frame(width:UIScreen.main.bounds.width * 0.9, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                    )
                    .padding()
            }
        }
    }
    
    func recordingWasStarted() -> Bool {
        if questionType == .melodyPlay {
            return false
        }
        if answerState == .notEverAnswered {
            DispatchQueue.main.async {
                //sleep(1)
                answerState = .recording
                metronome.stopTicking()
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    self.isTapping = true
                    tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                } else {
                    audioRecorder.startRecording(fileName: contentSection.name)
                }
            }
            return true
        }
        return false
    }
    
    func nextStepText() -> String {
        var next = ""
        if questionType == .melodyPlay {
            if contentSection.getExamTakingStatus() == .inExam {
                next = "Submit Your Answer"
            }
            else {
                next = "See The Answer"
            }
        }
        else {
            next = contentSection.getExamTakingStatus() == .inExam ? "Submit" : "Check"
            next += " Your Answer"
        }
        return next
    }
    
    func log()->Bool {
        return true
    }
    
    func shouldPlayRecording() ->Bool {
        var play = false
        if contentSection.getExamTakingStatus() == .inExam {
            if questionType == .rhythmEchoClap && answerState != .recorded{
                play = true
            }
        }
        else {
            play = true
        }
        return play
    }
    
    func buttonsView() -> some View {
        VStack {
            HStack {
                if contentSection.getExamTakingStatus() == .inExam && answerState != .recorded {
                    Button(action: {
                        self.contentSection.playExamInstructions(withDelay: true, onStarted: examInstructionsAreReading)
                    }) {
                        Text("Repeat Instructions").defaultButtonStyle()
                    }
                    .padding()
                }
            }
            HStack {
                //if contentSection.parent != nil {
                    if answerState != .recording {
                        if shouldPlayRecording() {
                            let uname = questionType == .melodyPlay ? "Melody" : "Rhythm"
                            PlayRecordingView(buttonLabel: "Hear The Given \(uname)",
                                              score: score,
                                              metronome: metronome,
                                              fileName: contentSection.name,
                                              onDone: {rhythmHeard = true})
                        }
                    }
                //}
                if answerState == .recorded {
                    if !(contentSection.getExamTakingStatus() == .inExam) {
                        PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                          score: questionType == .melodyPlay ? nil : getStudentTappingAsAScore(),
                                          metronome: self.metronome,
                                          fileName: contentSection.name,
                                          onStart: ({
                            if questionType != .melodyPlay {
                                if let recordedScore = getStudentTappingAsAScore() {
                                    if let recordedtempo = recordedScore.tempo {
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
                }
            }
        }
    }
    
    func recordingStartView() -> some View {
        VStack {
            ///For echo clap present the tapping view right after the rhythm is heard (without requiring a button press)
            if questionType == .melodyPlay || questionType == .rhythmVisualClap || !recordingWasStarted() {
                Button(action: {
                    if contentSection.getExamTakingStatus() == .inExam {
                        self.audioRecorder.stopPlaying()
                    }
                    answerState = .recording
                    metronome.stopTicking()
                    if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                        self.isTapping = true
                        tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                    } else {
                        audioRecorder.startRecording(fileName: contentSection.name)
                    }
                }) {
                    if answerState == .recorded {
                        if !(contentSection.getExamTakingStatus() == .inExam) {
                            Text("Redo Recording")
                                .defaultButtonStyle(enabled: rhythmHeard || questionType != .intervalAural)
                        }
                    }
                    else {
                        Text("Start Recording")
                            .defaultButtonStyle(enabled: rhythmHeard || questionType != .intervalAural)
                    }
                }
                .disabled(!(rhythmHeard || questionType != .intervalAural))
            }
        }
    }
    
    var body: AnyView {
        AnyView(
            VStack {
                if contentSection.getExamTakingStatus() == .inExam {
                    Text(" ")
                }
                else {
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
                    ScoreView(score: score).padding()
                    ScoreSpacerView()
                }
                
                VStack {
                    if answerState != .recording {
                        if contentSection.getExamTakingStatus() == .inExam {
                            Text(examInstructionsStartedStatus).font(.title).padding()
                        }
                        else {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                instructionView()
                            }
                        }
                        buttonsView()
                        Text(" ")
                        if rhythmHeard || questionType == .melodyPlay || questionType == .rhythmVisualClap {
                            recordingStartView()
                        }
                    }
                    
                    if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                        if answerState == .recording {
                            if questionType == .rhythmEchoClap {
                                PlayRecordingView(buttonLabel: "Hear The Given Rhythm Again",
                                                  score: score,
                                                  metronome: metronome,
                                                  fileName: contentSection.name,
                                                  onDone: {})
                            }
                        
                            TappingView(isRecording: $isTapping, tapRecorder: tapRecorder, onDone: {
                                answerState = .recorded
                                self.isTapping = false
                                answer.values = self.tapRecorder.stopRecording(score:score)
                                isTapping = false
                            })
                         }
                    }
                    
                    if questionType == .melodyPlay {
                        if answerState == .recording {
                            Button(action: {
                                answerState = .recorded
                                audioRecorder.stopRecording()
                                answer.recordedData = self.audioRecorder.getRecordedAudio(fileName: contentSection.name)
                            }) {
                                Text("Stop Recording")
                                    .defaultButtonStyle()
                            }
                            .padding()
                        }
                    }
                    if log() {
                        if answerState == .recorded {
                            HStack {
                                Button(action: {
                                    answerState = .submittedAnswer
                                    if questionType == .melodyPlay {
                                        answer.correct = true
                                    }
                                    else {
                                        answer.correct = rhythmIsCorrect()
                                    }
                                    score.setHiddenStaff(num: 1, isHidden: false)
                                }) {
                                    Text(nextStepText()).defaultButtonStyle()
                                }
                                .padding()
                            }
                        }
                    }
            }
            .onAppear() {
                //self.initScore()
                if contentSection.getExamTakingStatus() == .inExam {
                    self.contentSection.playExamInstructions(withDelay: true, onStarted: examInstructionsAreReading)
                }
                //score.setHiddenStaff(num: 1, isHidden: true)
                metronome.setTempo(tempo: 90, context: "View init")
                if questionType == .rhythmEchoClap || questionType == .melodyPlay {
                    metronome.setAllowTempoChange(allow: true)
                }
                else {
                    metronome.setAllowTempoChange(allow: false)
                }
            }
            .onDisappear() {
                self.audioRecorder.stopPlaying()
                //self.metronome.stopPlayingScore()
            }
        }
        .font(.system(size: UIDevice.current.userInterfaceIdiom == .phone ? UIFont.systemFontSize : UIFont.systemFontSize * 1.6))
        )
    }
    
    func examInstructionsAreReading(status:RequestStatus) {
        if status == .success {
            examInstructionsStartedStatus = ""
        }
        else {
            examInstructionsStartedStatus = "Could not read instructions"
        }
    }
}

struct ClapOrPlayAnswerView: View {
    let contentSection:ContentSection
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared
    //@ObservedObject
    var answerMetronome:Metronome
    
    @State var playingCorrect = false
    @State var playingStudent = false
    @State var speechEnabled = false
    @State var fittedScore:Score?

    private var score:Score
    private var questionType:QuestionType
    private var answer:Answer
    let questionTempo = 90
    
    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        self.answerMetronome = Metronome.getMetronomeWithCurrentSettings(ctx:"ClapOrPlayAnswerView")
        self.answer = answer
        answerMetronome.setSpeechEnabled(enabled: self.speechEnabled)
    }
    
    func analyseStudentRhythm() {
        guard let tapValues = answer.values else {
            return
        }
        
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        tappedScore.label = "Your Rhythm"
        
        ///Checks -
        ///1) all notes in the question have taps at the same time location
        ///2) no taps are in a location where there is no question note
        ///
        ///If the student got the test correct then ensure that what they saw that they tapped exaclty matches the question.
        ///Otherwise, try to make the studnets tapped score look the same as the question score up until the point of error
        ///(e.g. a long tap might correctly represent either a long note or a short note followed by a rest. So mark the tapped score accordingingly

        //score.flagNotesMissingRequiredTap(tappingScore: tappedScore)
        
        let fitted = score.fitScoreToQuestionScore(tappedScore:tappedScore)
        self.fittedScore = fitted.0
        let feedback = fitted.1
        
        if self.fittedScore == nil {
            return
        }

        self.answerMetronome.setAllowTempoChange(allow: false)
        self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")

        if let fittedScore = self.fittedScore {
            if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
                feedback.correct = true
                feedback.feedbackExplanation = "Good job!"
                if let recordedTempo = tappedScore.tempo {
                    self.answerMetronome.setAllowTempoChange(allow: true)
                    self.answerMetronome.setTempo(tempo: recordedTempo, context: "ClapOrPlayAnswerView")
                    let questionTempo = Metronome.getMetronomeWithCurrentSettings(ctx: "for clap answer").tempo
                    let tolerance = Int(CGFloat(questionTempo) * 0.2)
                    if questionType == .rhythmVisualClap {
                        feedback.feedbackExplanation! +=
                        " Your tempo was \(recordedTempo)."
                    }
                    if questionType == .rhythmEchoClap {
                        feedback.feedbackExplanation! +=
                        " Your tempo was \(recordedTempo) "
                        if recordedTempo < questionTempo - tolerance || recordedTempo > questionTempo + tolerance {
                            feedback.feedbackExplanation! +=
                            "which was \(recordedTempo < questionTempo ? "slower" : "faster") than the question tempo \(questionTempo) you heard."
                        }
                        else {
                            feedback.feedbackExplanation! += "."
                        }
                    }
                }
            }
            else {
                feedback.correct = false
            }
            //print("==========", self.fittedScore == nil, fittedScore == nil, feedback == nil)
            self.fittedScore!.setStudentFeedback(studentFeedack: feedback)
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
    
    func nextButtons(answerWasCorrect:Bool) -> some View {
        VStack {
            Text(" ")
            HStack {
                if answerWasCorrect {
                    Spacer()
                    Button(action: {
                        let parent = self.contentSection.parent
                        if let parent = parent {
                            parent.setSelected((parent.selectedIndex ?? 0) - 1)
                        }
                    }) {
                        HStack {
//                            Image(systemName: "arrow.left")
//                                .foregroundColor(.blue)
//                                .font(.largeTitle)
                            Text("\u{2190} Previous").defaultButtonStyle()
                        }
                    }
                    Spacer()

                    Button(action: {
                        let parent = self.contentSection.parent
                        if let parent = parent {
                            parent.setSelected((parent.selectedIndex ?? 0) + 1)
                        }
                    }) {
                        HStack {
                            Text("Next \u{2192}").defaultButtonStyle()
//                            Image(systemName: "arrow.right")
//                                .foregroundColor(.blue)
//                                .font(.largeTitle)
                        }
                    }
                    Spacer()
                    Button(action: {
                        if let parent = self.contentSection.parent {
                            let c = parent.subSections.count
                            let r = Int.random(in: 0...c)
                            parent.setSelected(r)
                        }
                    }) {
                        HStack {
                            Text("\u{2191} Shuffle").defaultButtonStyle()
//                            Image(systemName: "arrow.up")
//                                .foregroundColor(.blue)
//                                .font(.largeTitle)
                        }
                    }
                    Spacer()
                }
                else {
                    Button(action: {
                        let parent = self.contentSection.parent
                        if let parent = parent {
                            parent.setSelected(parent.selectedIndex ?? 0)
                        }
                    }) {
                        Text("Try Again").defaultButtonStyle()
                    }
                }
            }
        }
    }
    
//    func log(_ score:Score) -> Bool {
//    print ("========", score == nil, score.studentFeedback == nil)
//       return true
//    }
    
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
                if let fittedScore = self.fittedScore {
                    Text(" ")
                    ScoreSpacerView()
                    ScoreView(score: fittedScore).padding()
                    ScoreSpacerView()
                }

                HStack {
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
                        if let fittedScore = self.fittedScore {
                            PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                              score: fittedScore,
                                              metronome: answerMetronome,
                                              fileName: contentSection.name)
                        }
                    }
                }
                
                if contentSection.getExamTakingStatus() == .notInExam {
                    if let fittedScore = self.fittedScore {
                        //if log(fittedScore) {
                            if let studentFeedback = fittedScore.studentFeedback {
                                Spacer()
                                nextButtons(answerWasCorrect: studentFeedback.correct)
                                Spacer()
                            }
                        //}
                    }
                }
                Spacer() //Keep - required to align the page from the top
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
                audioRecorder.stopPlaying()
                //Metronome.shared.stopTicking()
            }
        )
    }
}

struct ClapOrPlayView: View {
    let contentSection: ContentSection
    @ObservedObject var logger = Logger.logger
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    let id = UUID()
    let questionType:QuestionType
    
    ///@State properties are automatically initialized by SwiftUI. You're not supposed to give them initial values in your custom initializers. By removing @State, you're allowed to manage the property's initialization yourself, as you've done in your init().
    var score:Score

    init(questionType:QuestionType, contentSection:ContentSection, answerState:Binding<AnswerState>, answer:Binding<Answer>) {
        self.questionType = questionType
        self.contentSection = contentSection
        _answerState = answerState
        _answer = answer
        self.score = contentSection.parseData(staffCount: questionType == .melodyPlay ? 2 : 1, onlyRhythm: questionType == .melodyPlay ? false : true)
        //self.score.debugScore("ClapOrPlayView", withBeam: false)
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
                .frame(width: UIScreen.main.bounds.width)
                Spacer()
            }
            else {
                if shouldShowAnswer() {
                    ZStack {
                        ClapOrPlayAnswerView(contentSection: contentSection,
                                             score: score,
                                             answer: answer,
                                             questionType: questionType)
                        if !contentSection.isExamTypeContentSection() {
                            if !(self.questionType == .melodyPlay) {
                                FlyingImageView(answer: answer)
                            }
                        }
                    }
                }
                Spacer() //Force it to align from the top
            }
        }
        .background(UIGlobals.colorBackground)
        .onAppear() {
        }
        .onDisappear {
            let metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "")
            metronome.stopTicking()
            metronome.stopPlayingScore()
        }
    }

}
