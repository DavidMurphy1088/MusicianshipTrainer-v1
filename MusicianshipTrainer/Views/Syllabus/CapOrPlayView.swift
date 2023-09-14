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

    @State var tappingView:TappingView? = nil
    @State private var helpPopup = false
    @State var isTapping = false
    @State var rhythmHeard:Bool
    @State private var examInstructions:Data? = nil

    var questionType:QuestionType
    //var examMode:Bool
    let questionTempo = 90
    let googleAPI = GoogleAPI.shared

    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh_unused:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        self.questionType = questionType
        self.rhythmHeard = false
        //self.examMode = contentSection.isInExam()
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
                if entry is Rest {
                    let timeSlice = score.addTimeSlice()
                    timeSlice.addRest(rest: entry as! Rest)
                }
            }
        }
        if staff == nil {
            //TODO remove when conversion to cloud content is done
            staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: (questionType == .rhythmVisualClap || questionType == .rhythmEchoClap) ? 1 : 5)
            score.setStaff(num: 0, staff: staff!)
        }
        if questionType == .melodyPlay {
            if let lastTimeSlice = score.getLastTimeSlice() {
                ///Place tonic on last timeslice
                ///Place dominant on previous bar
                let lastNote = lastTimeSlice.getTimeSliceNotes()[0]
                let entries = score.scoreEntries
                var barCount = 0
                for i in stride(from: entries.count - 2, through: 0, by: -1) {
                    if entries[i] is BarLine {
                        barCount += 1
                        if let nextTimeSlice:TimeSlice = entries[i+1] as? TimeSlice {
                            let scaleStartMidi = score.key.getScaleStartMidi()
                            if barCount == 1 {
                                nextTimeSlice.addTriadAt(rootNoteMidi: scaleStartMidi, value: lastNote.getValue(), staffNum: 1)
                                let keyTag:String = score.key.getKeyTagName()
                                nextTimeSlice.setTags(high: keyTag, low: "I")
                            }
                            if contentSection.getGrade() == 2 {
                                if barCount == 2 {
                                    let dominant:String
                                    switch score.key.keySig.accidentalCount {
                                    case 1:
                                        dominant = "D"
                                    case 2:
                                        dominant = "A"
                                    case 3:
                                        dominant = "E"
                                    case 4:
                                        dominant = "B"
                                    default:
                                        dominant = "G"
                                    }
                                    nextTimeSlice.addTriadAt(rootNoteMidi: scaleStartMidi - 5, value: lastNote.getValue(), staffNum: 1)
                                    let keyTag:String = dominant
                                    nextTimeSlice.setTags(high: keyTag, low: "V")
                                }
                            }
                        }
                        if barCount >= 2 {
                            break
                        }
                    }
                }
            }
            let bstaff = Staff(score: score, type: .bass, staffNum: 1, linesInStaff: questionType == .rhythmVisualClap ? 1 : 5)
            bstaff.isHidden = true
            score.setStaff(num: 1, staff: bstaff)
        }
    }
    
    func getExamInstructions() {
        let filename = "Instructions.wav"
        var pathSegments = self.contentSection.getPathAsArray()
        //remove the exam title from the path
        pathSegments.remove(at: 2)
        googleAPI.getFileDataByName(pathSegments: pathSegments, fileName: filename, reportError: true) {status, fromCache, data in
            if examInstructions == nil {
                examInstructions = data
                DispatchQueue.global(qos: .background).async {
                    if fromCache {
                        sleep(3)
                    }
                    audioRecorder.playFromData(data: data!)
                }
            }
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
        let tappingScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        score.flagNotesMissingRequiredTap(tappingScore: tappingScore)
        return score.errorCount() == 0 && tappingScore.errorCount() == 0
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
            GeometryReader { geo in
            //VStack  {
                VStack {
                    if self.isTakingExam() {
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
                            if self.isTakingExam() {
                                if self.examInstructions == nil {
                                    Text("Waiting for instructions...").defaultTextStyle().padding()
                                }
                            }
                            else {
                                VStack {
                                    Text(self.getInstruction(mode: self.questionType))
                                        .defaultTextStyle()
                                        .padding()
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                                )
                            }
                            
                            if rhythmHeard || questionType == .melodyPlay {
                                Button(action: {
                                    if self.isTakingExam() {
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
                                    Text(answerState == .notEverAnswered ? "Start Recording" : "Redo Recording")
                                        .defaultButtonStyle()
                                    //                                    .foregroundColor(.white).padding().background(rhythmHeard || questionType == .melodyPlay ? Color.blue : Color.gray).cornerRadius(UIGlobals.buttonCornerRadius).padding()
                                        .onAppear() {
                                            tappingView = TappingView(isRecording: $isTapping, tapRecorder: tapRecorder)
                                        }
                                }
                                .disabled(!rhythmHeard && questionType != .melodyPlay)
                            }
                        }
                        
                        if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                            
                            VStack {
                                tappingView
                                    .frame(height: geo.size.height / 4.0)
                            }
                            .padding()
                        }
                        
                        if answerState == .recording {
                            Button(action: {
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
                                Text("Stop Recording").defaultButtonStyle()
                            }
                            Spacer()
                        }
                        
                        if answerState == .recorded {
                            
                            if replayRecordingAllowed() {
                                PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                                  score: questionType == .melodyPlay ? nil : getStudentTappingAsAScore(),
                                                  metronome: self.metronome,
                                                  fileName: contentSection.name,
                                                  onStart: ({
                                    if questionType != .melodyPlay {
                                        if let recordedScore = getStudentTappingAsAScore() {
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
                                    .defaultButtonStyle()
                            }
                            .padding()
                        }
                    }
                    Spacer() //Keep - required to align the page from the top
                //}
                }
                .onAppear() {
                    self.initScore()
                    if self.isTakingExam() {
                        self.getExamInstructions()
                    }
                    score.setHiddenStaff(num: 1, isHidden: true)
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
                    self.metronome.stopTicking()
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
    @State var fittedScore:Score?

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
        
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        
        self.tappingScore = tappedScore
        guard let tappingScore = tappingScore else {
            return
        }

        ///Checks -
        ///1) all notes in the question have taps at the same time location
        ///2) no taps are in a location where there is no question note
        
        score.flagNotesMissingRequiredTap(tappingScore: tappingScore)
        
        self.fittedScore = score.fitScoreToQuestionScore(tappedScore:tappedScore)
        guard let fittedScore = fittedScore else {
            return
        }

        ///If the student got the test correct then ensure that what they saw that they tapped exaclty matches the question.
        ///Otherwise, try to make the studnets tapped score look the same as the question score up until the point of error
        ///(e.g. a long tap might correctly represent either a long note or a short note followed by a rest. So mark the tapped score accordingingly
        

        if score.errorCount() > 0 {
            self.answerMetronome.setAllowTempoChange(allow: false)
            self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")
            let studentFeedack = StudentFeedback()
            studentFeedack.feedbackExplanation = "There was no tap for \(score.errorCount() > 1 ? "these notes" : "this note") at the right time."
            score.setStudentFeedback(studentFeedack: studentFeedack)
        }
        
        if fittedScore.errorCount() > 0 {
            self.answerMetronome.setAllowTempoChange(allow: false)
            self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")
            let studentFeedack = StudentFeedback()
            studentFeedack.feedbackExplanation = "\(fittedScore.errorCount() > 1 ? "These taps don't" : "This tap does not") match a note in the question."
            fittedScore.setStudentFeedback(studentFeedack: studentFeedack)
        }
        
        if fittedScore.errorCount() == 0 && score.errorCount() == 0 {
            ///Student is correct so ensure that what they saw that they tapped exactly matches the question.
            fittedScore.copyEntries(from: score)

            let studentFeedack = StudentFeedback()
            if let recordedTempo = tappedScore.recordedTempo {
                self.answerMetronome.setTempo(tempo: recordedTempo, context: "Analyse Student - passed", allowBeyondLimits: true)
                studentFeedack.tempo = recordedTempo
            }
            self.answerMetronome.setAllowTempoChange(allow: true)
            studentFeedack.correct = true
            studentFeedack.feedbackExplanation = "Good job"
            fittedScore.setStudentFeedback(studentFeedack: studentFeedack)
        }
        else {
            //let fittedScore = score.fitScoreToQuestionScore(tappedScore:tappedScore)
            //fittedScore.copyEntries(from: fittedScore)
        }
        tappingScore.label = "Your Rhythm"
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
                    Text(" TEMP - AS RECORDED ... ")
                    ScoreSpacerView()
                    ScoreView(score: tappingScore).padding()
                    ScoreSpacerView()
                }
                if let fittedScore = self.fittedScore {
                    Text(" ")
                    ScoreSpacerView()
                    ScoreView(score: fittedScore).padding()
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
                        ///Only reply studnt rhythm from the tapped score so they know exactly what they tapped.
                        ///So tap hilights wont be seen unless the tapped score is visible but the played back rhythm will be accurate.
//                        if let fittedScore = self.fittedScore {
//                            PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
//                                              score: fittedScore,
//                                              metronome: answerMetronome,
//                                              fileName: contentSection.name)
//                        }
                    }
                    
                    Spacer() //Keep - required to align the page from the top
                }

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

    @State var refresh:Bool = false

    let id = UUID()
    let questionType:QuestionType
    
    @State var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5, noteSize: .small)
   
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
