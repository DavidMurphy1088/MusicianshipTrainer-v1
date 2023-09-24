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
                    let songs = Songs()
                    let base = firstNote
                    let interval = secondNote.midiNumber - firstNote.midiNumber
                    let timeSlice = TimeSlice(score: score)
                    let (melodyName, notes) = songs.song(timeSlice: timeSlice, base: base, interval: interval)
                    if let melodyName = melodyName {
                        self.melodyName = melodyName
                    }
                    player.playNotes(notes: notes)
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

    @State private var examInstructions:Data? = nil

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
        self.intervals = Intervals(grade: grade)
    }

    func initView() {
        let exampleData = contentSection.parseData(score: score) //contentSection.parent!.name, contentSection.name, exampleKey: contentSection.gr)
        
        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
        self.score.setStaff(num: 0, staff: staff)
        let chord:Chord = Chord()
        if let entries = exampleData {
            for entry in entries {
                if entry is KeySignature {
                    let keySignature = entry as! KeySignature
                    //Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                    score.setKey(key: Key(type: .major, keySig: keySignature))
                }

                if entry is Note {
                    let timeSlice = self.score.addTimeSlice()
                    let note = entry as! Note
                    timeSlice.addNote(n: note)
                    intervalNotes.append(note)
                    if questionType == .intervalAural {
                        chord.addNote(note: Note(timeSlice: timeSlice, num: note.midiNumber, value: 2, staffNum: 0, accidental: note.accidental))
                    }
                }
                if entry is TimeSignature {
                    let ts = entry as! TimeSignature
                    score.timeSignature = ts
                }
            }
        }
        if chord.getNotes().count > 0 {
            score.addTimeSlice().addChord(c: chord)
        }
    }
    
    func buildAnser(grade:Int) {
        if intervalNotes.count == 0 {
            return
        }
        let staff = score.getStaff()[0]
        let offset1 = intervalNotes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offset2 = intervalNotes[1].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        var explanation = ""
        
        if offset1 % 2 == 0 {
            explanation = "A line to a "
            if offset2 % 2 == 0 {
                explanation += "line is a skip"
            }
            else {
                explanation += "space is a step"
            }
        }
        else {
            explanation = "A space to a "
            if offset2 % 2 == 0 {
                explanation += "line is a step"
//                if grade == 1 {
//                    explanation += "a step"
//                }
//                else {
//                    explanation += "a step"
//                }
            }
            else {
                explanation += "space is a skip"
            }
        }
        if grade == 1 {
            answer.explanation = explanation
        }

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
                VStack {
                    let intervalsForColumn = intervals.getVisualColumns(col: column)
                    ForEach(intervalsForColumn, id: \.name) { intervalType in
                        Button(action: {
                            selectedIntervalName = intervalType.name
                            answerState = .answered
                            answer.selectedIntervalName = intervalType.name
                        }) {
                            Text(intervalType.name)
                                .defaultButtonStyle()
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(scoreWasPlayed ? Color.black : Color.clear, lineWidth: 1)
                                        .background(selectedIntervalName == intervalType.name ? UIGlobals.colorInstructions : Color.clear)
                                )
                        }
                    }
                }
                .padding(.top, 0)
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
                        sleep(2)
                    }
                    audioRecorder.playFromData(data: data!)
                }
            }
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
                    ScoreView(score: score).padding().opacity(questionType == .intervalAural ? 0.0 : 1.0)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ScoreSpacerView()
                        ScoreSpacerView()
                        ScoreSpacerView()
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
                                Text("Hear The Interval").defaultButtonStyle()
                            }
                            .padding()
                            Text("").padding()
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                        )
                        .background(UIGlobals.colorScore)
                    }
                }
                                
                 VStack {
                    if isTakingExam() {
                        if self.examInstructions == nil {
                            Text("Waiting for instructions...").defaultTextStyle().padding()
                        }
                    }
                    else {
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text("Please select the correct interval").defaultTextStyle().padding()
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
                            self.buildAnser(grade: contentSection.getGrade())
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
                    self.getExamInstructions()
                }
            }
            .onDisappear() {
                //if self.examMode {
                    self.audioRecorder.stopPlaying()
                //}
            }
        )
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
    
    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.noteIsSpace = true
        metronome.speechEnabled = false
        self.questionType = questionType
        self.answer = answer
        self.grade = contentSection.getGrade()
        self.intervals = Intervals(grade: grade)
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
                    //if questionType == .intervalAural {
                    Button(action: {
                        //metronome.setTempo(tempo: 200, context: "Intervals Viz")
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval").defaultButtonStyle()
                    }
                    .padding()
                    //}
                    
                    PlayExampleMelody(score: score).padding()
                }
                
                Spacer()
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
            //print("==========================Interval View On Appear State:", answerState, "answer", answer.correctInterval, answer.selectedInterval)
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
