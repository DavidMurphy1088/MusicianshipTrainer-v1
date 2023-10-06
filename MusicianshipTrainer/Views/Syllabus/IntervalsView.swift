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

struct PlayExampleMelody : View {
    let score:Score
    @State private var showExamplePopover = false
    @State var melodyName: String = ""
    let player = AudioSamplerPlayer.getShared()

    var body : some View {
        Button(action: {
            showExamplePopover = true
            var secondNote:Note?
            var firstNote:Note?
            for timeSlice in score.getAllTimeSlices() {
                let notes = timeSlice.getTimeSliceNotes()
                if notes.count > 0 {
                    let note = notes[0]
                    if firstNote == nil {
                        firstNote = note
                    }
                    else {
                        if secondNote == nil {
                            secondNote = note
                        }
                    }
                }
            }
            if let firstNote = firstNote {
                if let secondNote = secondNote {
                    let melodies = Melodies.shared
                    //let base = firstNote
                    let halfSteps = secondNote.midiNumber - firstNote.midiNumber
                    //let timeSlice = TimeSlice(score: score)
                    let melody = melodies.getMelodies(halfSteps: halfSteps)
                    self.melodyName = melodyName
                    player.playNotes(notes: melody[0].notes)
                }
            }
        }) {
            Text("Hear Melody").defaultButtonStyle()
        }
        .alert(isPresented: $showExamplePopover) {
            Alert(title: Text("Example"),
                  //message: Text(songName).font(.title),
                  message: Text(self.melodyName).font(.title),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear() {
            //AudioSamplerPlayer.shared.startSampler()
        }
        .onDisappear() {
            //AudioSamplerPlayer.shared.stopSampler()
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
        contentSection.parseData(score: score, staff:staff, onlyRhythm: false) //contentSection.parent!.name, contentSection.name, exampleKey: contentSection.gr)
        
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
            if let chord = chord {
                timeslice?.addChord(c: chord)
            }
            if intervalNotes.count >= 2 {
                break
            }

        }
    }
    
    func buildAnswer(grade:Int) {
        if intervalNotes.count == 0 {
            return
        }
        let staff = score.getStaff()[0]
        let offset1 = intervalNotes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offset2 = intervalNotes[1].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        //var explanation = ""
        
        let explanation = intervals.getExplanation(grade: contentSection.getGrade(), offset1: offset1, offset2: offset2)
        answer.explanation = explanation
        
        let interval = abs((intervalNotes[1].midiNumber - intervalNotes[0].midiNumber))
        answer.correct = false
        for intervalType in intervals.intervalTypes {
            if intervalType.intervals.contains(interval) {
                answer.correctIntervalName = intervalType.name
                if answer.correctIntervalName == answer.selectedIntervalName {
                    answer.correct = true
                }
                break
            }
        }
    }

    var selectIntervalView : some View {
        HStack(alignment: .top)  {
            let columns = intervals.getVisualColumnCount()
            ForEach(0..<columns) { column in
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
                                .defaultButtonStyle(enabled: scoreWasPlayed || questionType == .intervalVisual)
                                .padding()
                        }
                    }
                }
                .padding(.top, 0)
                Spacer()
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
                        Button(action: {
                            audioRecorder.stopPlaying()
                            self.contentSection.playExamInstructions(withDelay:false, onStarted: examInstructionsAreReading)
                        }) {
                            Text("Hear The Instructions").defaultButtonStyle()
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
                    if isTakingExam() {
                        if let status = examInstructionsStartedStatus {
                            Text(status)
                        }
                        else {
                            Text("Waiting for Instructions..")
                        }
                    }
                    else {
                        if scoreWasPlayed {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Text("Please select the correct interval").defaultTextStyle().padding()
                            }
                        }
                    }
                    HStack {
                        selectIntervalView.padding()
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

struct ShowMelodiesView: View {
    let firstNote:Note
    let intervalName:String
    let melodies:[Melody]
    @State var selectedMelodyId:UUID?
    @State var showingMelodies = false

    var body: some View {
        VStack {
            Button(action: {
                showingMelodies = true
            }) {
                Text("Hear Melody").defaultButtonStyle()
            }
            .padding()
            .popover(isPresented: $showingMelodies, arrowEdge: .trailing) {
                VStack {
                    HStack {
                        ForEach(melodies, id: \.id) { melody in
                            Button(action: {
                                selectedMelodyId = melody.id
                                let transposed = melody.transpose(base: firstNote)
                                AudioSamplerPlayer.getShared().stopPlaying()
                                AudioSamplerPlayer.getShared().playNotes(notes: transposed)
                            }) {
                                Text(melody.name)
                                    .padding()
                                    .foregroundColor(selectedMelodyId == melody.id ? .white : .primary)
                                    .background(selectedMelodyId == melody.id ? Color.blue : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct IntervalAnswerView: View {
    let contentSection:ContentSection
    private var questionType:QuestionType
    private var score:Score
    private let imageSize = Double(32)
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
        var result:[Melody] = []
        let timeSlices = score.getAllTimeSlices()
        if timeSlices.count < 2 {
            return result
        }
        let firstNote = timeSlices[0].getTimeSliceNotes()[0]
        let halfSteps = timeSlices[1].getTimeSliceNotes()[0].midiNumber - firstNote.midiNumber
        return melodies.getMelodies(halfSteps: halfSteps)
    }
    
    func nextButtons(answerWasCorrect:Bool) -> some View {
        HStack {
            if answerWasCorrect {
                Spacer()
                Button(action: {
                    if let parent = self.contentSection.parent {
                        let c = parent.subSections.count
                        let r = Int.random(in: 0...c)
                        parent.setSelected(r)
                    }
                }) {
                    Text("Try A Shuffle Question").defaultButtonStyle()
                }
                Spacer()
                Button(action: {
                    let parent = self.contentSection.parent
                    if let parent = parent {
                        parent.setSelected((parent.selectedIndex ?? 0) + 1)
                    }
                }) {
                    Text("Next Question").defaultButtonStyle()
                }
                Spacer()
                Button(action: {
                    let parent = self.contentSection.parent
                    if let parent = parent {
                        parent.setSelected((parent.selectedIndex ?? 0) - 1)
                    }
                }) {
                    Text("Previous").defaultButtonStyle()
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
                        Text("Correct - Good Job").defaultTextStyle()
                    }
                    else {
                        Image(systemName: "staroflife.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red)
                        Text("Sorry - not correct").defaultTextStyle()
                    }
                }
                .padding()
                
                if !answer.correct {
                    Text("You said that the interval was a \(answer.selectedIntervalName )").defaultTextStyle().padding()
                }
                Text("The interval is a \(answer.correctIntervalName)").defaultTextStyle().padding()
                if questionType == .intervalVisual {
                    Text(answer.explanation).defaultTextStyle().padding()
                }
                
                HStack {
                    Button(action: {
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval").defaultButtonStyle()
                    }
                    .padding()
                    
                    if getMelodies().count > 0 {
                        ShowMelodiesView(firstNote: score.getAllTimeSlices()[0].getTimeSliceNotes()[0], intervalName: answer.correctIntervalName, melodies: getMelodies())
                    }
                }
                
                if true || answer.correct {
                    Text("")
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
    @ObservedObject var logger = Logger.logger
    @Binding var answerState:AnswerState
    @Binding var answer:Answer 

    @State var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5, noteSize: .large) //neds to be @state to pass it around

    let id = UUID()
    let questionType:QuestionType
    
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
                        //FlyingImageView(answer: answer)
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

struct FlyingImageView: View {
    @State var answer:Answer
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    @State var yPos = 0.0
    @State var loop = 0
    let imageSize:CGFloat = 100.0
    let totalDuration = 15.0
    let delta = 100.0
    @State var rotation = -90.0
    @State var opacity = 1.0
    
    var body: some View {
        ZStack {
            Image(systemName: "airplane")
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(.blue)
                .opacity(opacity * 1.5)
                .rotationEffect(Angle(degrees: rotation))
                .position(position)
        }
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                sleep(1)
                if !answer.correct {
                    withAnimation(Animation.linear(duration: 1.0)) { //}.repeatForever(autoreverses: false)) {
                        rotation = 90.0
                    }
                }
                animateRandomly()
            }
        }
    }
    
    func animateRandomly() {
        let loops = 4
        for i in 0..<loops {
            var randomX = 0.0
            if answer.correct {
                yPos -= delta //CGFloat.random(in: imageSize/2 ... UIScreen.main.bounds.height - imageSize/2)
                randomX = CGFloat.random(in: imageSize * -1 ... imageSize * 1)
            }
            else {
                randomX = CGFloat.random(in: imageSize * -4 ... imageSize * 4)
                yPos += delta
            }
            
            withAnimation(Animation.linear(duration: totalDuration / Double(loops))) { //}.repeatForever(autoreverses: false)) {
                opacity = 0.0
                position = CGPoint(x: UIScreen.main.bounds.width / 2 + randomX, y: UIScreen.main.bounds.height / 2 + yPos)
            }
        }

    }
}
