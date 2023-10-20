import SwiftUI

struct ScoreSpacerView: View {
    var body: some View {
        VStack {
            Text(" ")
            Text(" ")
            Text(" ")
        }
    }
}

struct SelectIntervalView: View {
    @Binding var answer:Answer
    @Binding var answerState:AnswerState
    var intervals:Intervals
    @State var selectedIntervalName:String?
    var questionType:QuestionType
    var scoreWasPlayed:Bool
    
    var body: some View {
        HStack(alignment: .top)  {
            let columns:Int = intervals.getVisualColumnCount()
            ForEach(0..<columns) { column in
                //VStack {
                    Spacer()
                    VStack {
                        let intervalsForColumn = intervals.getVisualColumns(col: column)
                        ForEach(intervalsForColumn, id: \.name) { intervalType in
                            Button(action: {
                                selectedIntervalName = intervalType.name
                                answerState = .answered
                                answer.selectedIntervalName = intervalType.name
                            }) {
                                Text(intervalType.name)
                                    .selectedButtonStyle(selected: selectedIntervalName == intervalType.name)
                            }
                        }
                    }
                    .padding(.top, 0)
                    Spacer()
                }
           // }
        }
    }
}

struct IntervalPresentView: View { //}, QuestionPartProtocol {
    let contentSection:ContentSection
    var grade:Int
    @ObservedObject var score:Score
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared

    @State private var examInstructionsStartedStatus:String? = nil

    @State var intervalNotes:[Note] = []
    @State private var selectedIntervalName:String?
    @State private var selectedOption: String? = nil
    @State private var scoreWasPlayed = false
    @State var intervals:Intervals
    
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    
    let questionType:QuestionType
    let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"IntervalPresentView")
    let googleAPI = GoogleAPI.shared
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        //self.score = contentSection.parseData(onlyRhythm: false)
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        _answerState = answerState
        _answer = answer
        self.grade = contentSection.getGrade()
        self.intervals = Intervals(grade: grade, questionType: questionType)
    }

    func initView() {
        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
        self.score.setStaff(num: 0, staff: staff)
        
        var timeslice:TimeSlice?
        var chord:Chord?
        if questionType == .intervalAural {
            timeslice = score.createTimeSlice()
            chord = Chord()
        }
        for timeSlice in score.getAllTimeSlices() {
            if timeSlice.getTimeSliceNotes().count > 0 {
                let note = timeSlice.getTimeSliceNotes()[0]
                intervalNotes.append(note)
                if let chord = chord {
                    chord.addNote(note: Note(timeSlice: timeSlice, num: note.midiNumber, value:2, staffNum: note.staffNum))
                }
            }
        }
        if let chord = chord {
            timeslice?.addChord(c: chord)
        }
    }
    
    func buildAnswer(grade:Int) {
        if intervalNotes.count == 0 {
            return
        }
        let halfStepDifference = intervalNotes[1].midiNumber - intervalNotes[0].midiNumber
        
        let staff = score.getStaff()[0]
        let offset1 = intervalNotes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offset2 = intervalNotes[1].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offetDifference = abs(offset2 - offset1) 
        
        let explanation = intervals.getExplanation(grade: contentSection.getGrade(), offset1: offset1, offset2: offset2)
        answer.explanation = explanation
        
        func intervalOccursOnlyOnce(_ interval:Int) -> Bool {
            var ctr = 0
            for intervalName in intervals.intervalNames {
                if intervalName.intervals.contains(abs(interval)) {
                    ctr += 1
                }
            }
            return ctr == 1
        }
        
        answer.correct = false
        for intervalName in intervals.intervalNames {
            if intervalName.intervals.contains(abs(halfStepDifference)) {
                if intervalName.noteSpan == offetDifference || intervalOccursOnlyOnce(halfStepDifference) {
                    answer.correctIntervalName = intervalName.name
                    answer.correctIntervalHalfSteps = halfStepDifference
                    if intervalName.name == answer.selectedIntervalName  {
                        answer.correct = true
                        break
                    }
                }
            }
        }
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
    
    var body: some View {
        AnyView(
            VStack {
                VStack {
                    ScoreSpacerView() //keep for top ledger line notes
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ScoreSpacerView()
                    }
                    //keep the score in the UI for consistent UIlayout between various usages of this view
                    if questionType == .intervalVisual {
                        ScoreView(score: score).padding().opacity(questionType == .intervalAural ? 0.0 : 1.0)
                    }
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ScoreSpacerView()
                        ScoreSpacerView()
                        ScoreSpacerView()
                    }
                    
                    if isTakingExam() {
                        if let status = examInstructionsStartedStatus {
                            Text(status).font(.title)
                        }
                        else {
                            Text("Waiting for Instructions...").font(.title)
                        }
                        Button(action: {
                            audioRecorder.stopPlaying()
                            self.contentSection.playExamInstructions(withDelay:false, onStarted: examInstructionsAreReading)
                        }) {
                            Text("Repeat The Instructions").defaultButtonStyle()
                        }
                        Text(" ")
                    }

                    if questionType == .intervalAural {
                        VStack {
                            Text("").padding()
                            Button(action: {
                                metronome.playScore(score: score, onDone: {
                                    self.scoreWasPlayed = true
                                })
                                self.scoreWasPlayed = true
                            }) {
                                ///In exam wait to hear instructions
                                Text("Hear The Interval").defaultButtonStyle(enabled: !self.isTakingExam() || examInstructionsStartedStatus != nil)
                            }
                            .padding()
                            Text("").padding()
                        }
//                        .overlay(
//                            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
//                        )
//                        .background(UIGlobals.colorScore)
                    }
                }
                                
                 VStack {

                    if !isTakingExam() {
                        if scoreWasPlayed {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Text("Please select the correct interval").defaultTextStyle().padding()
                            }
                        }
                    }
                    HStack {
                        SelectIntervalView(answer: $answer, answerState: $answerState, intervals: intervals,
                                           questionType: questionType, scoreWasPlayed: scoreWasPlayed)
                        .padding()
                    }
                    .padding()
                }
                .disabled(questionType == .intervalAural && scoreWasPlayed == false)
                if answerState == .answered {
                    VStack {
                        Button(action: {
                            self.buildAnswer(grade: contentSection.getGrade())
                            answerState = .submittedAnswer
                        }) {
                            Text("\(self.isTakingExam() ? "Submit" : "Check") Your Answer").defaultButtonStyle()
                        }
                        .padding()
                    }
                }
                Spacer()
            }
            .onAppear {
                self.initView()
                if self.isTakingExam() {
                    ///Delay on narrating if audio is delivered fast from cache and view only just loaded
                    self.contentSection.playExamInstructions(withDelay: true, onStarted: examInstructionsAreReading)
                }
            }
            .onDisappear() {
                self.audioRecorder.stopPlaying()
            }
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

struct IntervalAnswerView: View {
    let contentSection:ContentSection
    private var questionType:QuestionType
    private var score:Score
    private let imageSize = Double(48)
    private let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"Interval answer View")
    private var noteIsSpace:Bool
    private var answer:Answer
    private let intervals:Intervals
    private let grade:Int
    private let melodies = Melodies.shared

    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.noteIsSpace = true
        metronome.speechEnabled = false
        self.questionType = questionType
        self.answer = answer
        self.grade = contentSection.getGrade()
        self.intervals = Intervals(grade: grade, questionType: questionType)
    }
    
    func getMelodies() -> [Melody] {
        let result:[Melody] = []
        let timeSlices = score.getAllTimeSlices()
        if timeSlices.count < 2 {
            return result
        }
        let firstNote = timeSlices[0].getTimeSliceNotes()[0]
        let halfSteps = timeSlices[1].getTimeSliceNotes()[0].midiNumber - firstNote.midiNumber
        return melodies.getMelodies(halfSteps: halfSteps)
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
                            Image(systemName: "arrow.left")
                                .foregroundColor(.blue)
                                .font(.largeTitle)
                            Text("Previous").defaultButtonStyle()
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
                            Text("Next").defaultButtonStyle()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.blue)
                                .font(.largeTitle)
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
                            Text("Shuffle").defaultButtonStyle()
                            Image(systemName: "arrow.up")
                                .foregroundColor(.blue)
                                .font(.largeTitle)
                        }
                    }
                    Spacer()
                }
//                else {
//                    Button(action: {
//                        let parent = self.contentSection.parent
//                        if let parent = parent {
//                            parent.setSelected(parent.selectedIndex ?? 0)
//                        }
//                    }) {
//                        Text("Try Again").defaultButtonStyle()
//                    }
//                }
            }
        }
    }
        
    var body: AnyView {
        AnyView(
            VStack {
                ScoreSpacerView()
                ScoreView(score: score).padding()
                ScoreSpacerView()
                ScoreSpacerView()
                
                HStack {
                    if answer.correct {
                        Image(systemName: "checkmark.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green)
                        Text("Correct - Good Job")
                            //.defaultTextStyle()
                            .font(UIGlobals.correctAnswerFont)
                    }
                    else {
                        Image(systemName: "staroflife.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red)
                        Text("Sorry - not correct")
                            //.defaultTextStyle()
                            .font(UIGlobals.correctAnswerFont)
                    }
                }
                .padding()
                
                if !answer.correct {
                    Text("You said that the interval was a \(answer.selectedIntervalName )").defaultTextStyle().padding()
                }
                Text("The interval is a \(answer.correctIntervalName)").defaultTextStyle().padding()
                if questionType == .intervalVisual {
                    if answer.correct == false {
                        Text(answer.explanation).defaultTextStyle().padding()
                    }
                }
                
                HStack {
                    Button(action: {
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval").defaultButtonStyle()
                    }
                    .padding()
                    
                    if getMelodies().count > 0 {
                        ShowMelodiesView(firstNote: score.getAllTimeSlices()[0].getTimeSliceNotes()[0],
                                         intervalName: answer.correctIntervalName,
                                         interval: answer.correctIntervalHalfSteps, melodies: getMelodies())
                    }
                }
                
                if contentSection.getExamTakingStatus() == .notInExam {
                    Spacer()
                    nextButtons(answerWasCorrect: answer.correct)
                    Spacer()
                }
                else {
                    Spacer()
                }
            }
        )
    }
}

struct IntervalView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let contentSection:ContentSection
    ///@State properties are automatically initialized by SwiftUI. You're not supposed to give them initial values in your custom initializers. By removing @State, you're allowed to manage the property's initialization yourself, as you've done in your init().
    var score:Score
    
    @ObservedObject var logger = Logger.logger
    @Binding var answerState:AnswerState
    @Binding var answer:Answer 

    let id = UUID()
    let questionType:QuestionType
    
    init(questionType:QuestionType, contentSection:ContentSection, answerState:Binding<AnswerState>, answer:Binding<Answer>) {
        self.questionType = questionType
        self.contentSection = contentSection
        _answerState = answerState
        _answer = answer
        score = contentSection.parseData(staffCount: 1, onlyRhythm: false)
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
            if answerState  == .notEverAnswered || answerState  == .answered {
                IntervalPresentView(contentSection: contentSection,
                                    score: self.score,
                                    answerState: $answerState,
                                    answer: $answer,
                                    questionType:questionType)

            }
            else {
                if shouldShowAnswer() {
                    ZStack {
                        IntervalAnswerView(contentSection: contentSection,
                                           score: self.score,
                                           answer: answer,
                                           questionType:questionType)
                        FlyingImageView(answer: answer)
                    }
                }
            }
        }
        .onAppear() {
        }
        .background(UIGlobals.colorBackground)
        //.border(Color.red)
    }
}

