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

struct IntervalPresentView: View { //}, QuestionPartProtocol {
    let contentSection:ContentSection
    @ObservedObject var score:Score
    @ObservedObject private var logger = Logger.logger

    @State var intervalNotes:[Note] = []
    @State private var selectedIntervalIndex:Int = 10//? = nil
    @State private var selectedOption: String? = nil
    @State private var scoreWasPlayed = false
    @State var intervals:[IntervalName] = []
    @Binding var answerState:AnswerState
    @Binding var answer:Answer

    let questionType:QuestionType
    let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"IntervalPresentView")
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        _answerState = answerState
        _answer = answer
    }

    class IntervalName : Hashable, Comparable {
        var interval: Int
        var name:String
        var explanation:[String]
        var isIncluded = true
        
        static func < (lhs: IntervalPresentView.IntervalName, rhs: IntervalPresentView.IntervalName) -> Bool {
            return lhs.interval < rhs.interval
        }

        init(interval:Int, name:String, explanation:[String]) {
            self.interval = interval
            self.name = name
            self.explanation = explanation
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(interval)
        }
        static func == (lhs: IntervalPresentView.IntervalName, rhs: IntervalPresentView.IntervalName) -> Bool {
            return lhs.interval == rhs.interval
        }
    }
    
    func initView() {
        self.intervals  = [
                IntervalName(interval:1, name: "Second", //Minor
                                          explanation: ["",
                                                        ""]),
                IntervalName(interval:2, name: "Second", //Major
                                          explanation: ["A line to a space is a step",
                                                        "A space to a line is a step"]),
                IntervalName(interval:3, name: "Third", //Minor
                                        explanation: ["A line to a line is a skip",
                                                      "A space to a space is a skip"]),
                IntervalName(interval:4, name: "Third", //Major
                                        explanation: ["",""])
        ]
        let exampleData = contentSection.parseData() //contentSection.parent!.name, contentSection.name, exampleKey: contentSection.gr)
        
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
                        chord.addNote(note: Note(num: note.midiNumber, value: 2, accidental: note.accidental))
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
        for interval in intervals {
            if questionType == .intervalVisual {
                interval.isIncluded = interval.interval == 2 || interval.interval == 4
                //Grade 1 only talks about an interval as a 2nd or 3rd regardless of whether is minor or major
                //interval.isAnswerOption = interval.interval == 2 || interval.interval == 4
            }
            else {
                interval.isIncluded = interval.interval == 2 || interval.interval == 4
            }
        }
    }
    
    func buildAnser() {
        if intervalNotes.count == 0 {
            return
        }
        let interval = abs((intervalNotes[1].midiNumber - intervalNotes[0].midiNumber))
        let range = interval...interval+1
        //print (contentSection.answer.selectedInterval)
        if answer.selectedInterval != nil && range.contains(answer.selectedInterval!) {
            answer.correct = true
            answer.correctInterval = interval
        }
        else {
            answer.correct = false
            answer.correctInterval = interval
        }
        let name = intervals.first(where: { $0.interval == answer.correctInterval})
        if name != nil {
            answer.correctIntervalName = name!.name
            let noteIsSpace = [Note.MIDDLE_C + 5, Note.MIDDLE_C + 9, Note.MIDDLE_C + 12, Note.MIDDLE_C + 16].contains(intervalNotes[0].midiNumber)
            answer.explanation = name!.explanation[noteIsSpace ? 1 : 0]
        }
    }

    var selectIntervalView : some View {
        VStack(spacing: 0) {
            ForEach(Array(intervals.sorted().enumerated()), id: \.1) { index, interval in
                if interval.isIncluded {
                    Button(action: {
                        selectedIntervalIndex = index
                        answerState = .answered
                        answer.selectedInterval = intervals[index].interval
                    }) {
                        Text(interval.name)
                            .defaultStyle()
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(scoreWasPlayed ? Color.black : Color.clear, lineWidth: 1)
                                    //.background(selectedIntervalIndex == index ? Color(.systemTeal) : Color.clear)
                                    .background(selectedIntervalIndex == index ? UIGlobals.colorInstructions : Color.clear)
                            )
                    }
                    .padding()
                }
            }
        }
        .padding()
    }

    func isTakingExam() -> Bool {
        guard let parent = contentSection.parent else {
            return false
        }
        if parent.isExamTypeContentSection() && contentSection.answer11 == nil {
            return true
        }
        else {
            return false
        }
    }
    
    var body: some View {
        AnyView(
            VStack {
                //if questionType == .intervalVisual {
                    ScoreSpacerView()
                    ScoreSpacerView()
                    if questionType == .intervalVisual {
                        ScoreView(score: score).padding()
                    }
                    ScoreSpacerView()
                    ScoreSpacerView()
                    ScoreSpacerView()
                //}
                
                HStack {
                    if questionType != .intervalVisual {
                        Button(action: {
                            metronome.playScore(score: score, onDone: {
                                self.scoreWasPlayed = true
                            })
                            self.scoreWasPlayed = true
                        }) {
                            Text("Hear Interval").defaultStyle()
                        }
                    }
                }
                VStack {
                    Text("Is the interval a second or a third?").padding()
                    VStack {
                        selectIntervalView.padding()
                    }
                    .padding()
                }
                .disabled(questionType == .intervalAural && scoreWasPlayed == false)
                if answerState == .answered {
                    VStack {
                        Button(action: {
                            self.buildAnser()
                            //contentSection.setAnswerState(ctx:"Int View Present SUBMIT", .submittedAnswer)
                            answerState = .submittedAnswer
                        }) {
                            Text("\(self.isTakingExam() ? "Submit" : "Check") Your Answer").defaultStyle()
                        }
                        //.disabled(answer.state != .answered)
                        .padding()
                    }
                }
                Spacer()
            }
            .onAppear {
                print("==========================Interval Present View On Appear")
                self.initView()
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
    
    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.noteIsSpace = true //[Note.MIDDLE_C + 5, Note.MIDDLE_C + 9, Note.MIDDLE_C + 12, Note.MIDDLE_C + 16].contains(intervalNotes[0].midiNumber)
        metronome.speechEnabled = false
        self.questionType = questionType
        self.answer = answer
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
                    }
                    else {
                        Image(systemName: "staroflife.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red)
                        Text("Sorry - not correct")
                    }
                }
                .padding()
                
                Text("The interval is a \(answer.correctIntervalName)").padding()
                if questionType == .intervalVisual {
                    Text(answer.explanation).italic().fixedSize(horizontal: false, vertical: true).padding()
                }
                
                if questionType == .intervalAural {
                    Button(action: {
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval").defaultStyle()
                    }
                    .padding()
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

    @State var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5) //neds to be @state to pass it around

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
                    if contentSection.answer11 == nil {
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
                    IntervalAnswerView(contentSection: contentSection,
                                       score: self.score,
                                       answer: answer,
                                       questionType:questionType)
                }
            }
        }
        .onAppear() {
            print("==========================Interval View On Appear State:", answerState, "answer", answer.correctInterval, answer.selectedInterval)
        }
        .background(UIGlobals.colorBackground)
    }
}

