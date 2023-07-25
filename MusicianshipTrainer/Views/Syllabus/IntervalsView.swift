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
    @State var answer:Answer
    //@Binding var answer:Answer
    var score:Score
    let exampleData = ExampleData.shared
    var intervalNotes:[Note] = []
    @ObservedObject private var logger = Logger.logger
    @State private var selectedIntervalIndex:Int = 10//? = nil
    var questionType:QuestionType
    let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"IntervalPresentView")
    @State private var selectedOption: String? = nil
    @State private var scoreWasPlayed = false
    @ObservedObject var testMode: TestMode
    
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
    
    let intervals = [
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
                                explanation: ["",""]),
    ]
    
//    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType) -> QuestionPartProtocol {
//        var testMode = TestMode(mode: .exam, navigationPolicy: .can)
//        return IntervalPresentView(contentSection: contentSection, score:score, answer: answer, testMode: $testMode, questionType:questionType)
//    }
    
    func buildAnser() {
        
        if intervalNotes.count == 0 {
            return
        }
        let interval = abs((intervalNotes[1].midiNumber - intervalNotes[0].midiNumber))
        let range = interval...interval+1
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

    init(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.answer = answer
        self.score = score
        self.questionType = questionType
        let exampleData = exampleData.get(contentSection: contentSection) //contentSection.parent!.name, contentSection.name, exampleKey: contentSection.gr)
        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
        self.testMode = testMode
        self.score.setStaff(num: 0, staff: staff)
        let chord:Chord = Chord()
        if let entries = exampleData {
            
            for entry in entries {
                if entry is KeySignature {
                    let keySignature = entry as! KeySignature
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
    
    var selectIntervalView : some View {
        VStack(spacing: 0) {
            ForEach(Array(intervals.sorted().enumerated()), id: \.1) { index, interval in
                if interval.isIncluded {
                    Button(action: {
                        selectedIntervalIndex = index
                        answer.setState(.answered)
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

    var body: AnyView {
        AnyView(
            VStack {
                if questionType == .intervalVisual {
                    ScoreSpacerView()
                    ScoreSpacerView()
                    ScoreView(score: score).padding()
                    ScoreSpacerView()
                    ScoreSpacerView()
                    //ScoreView(score: score).padding()
                    ScoreSpacerView()
                }
                
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
                
                if answer.state == .answered {                    
                    //if testMode.mode == .practice {
                        VStack {
                            Button(action: {
                                self.buildAnser()
                                answer.setState(.submittedAnswer)
                            }) {
                                Text("\(testMode.mode == .exam ? "Submit" : "Check") Your Answer").defaultStyle()
                            }
                            //.disabled(answer.state != .answered)
                            .padding()
                        }
//                    }
//                    else {
//                        let a = answer.setState(.submittedAnswer)
//                    }
                }
                Spacer()
            }
        )
    }
    
}

struct IntervalAnswerView: View { //}, QuestionPartProtocol {
    @ObservedObject var answer:Answer
    private var questionType:QuestionType

    private var score:Score
    private let imageSize = Double(32)
    private let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"Interval answer View")
    private var noteIsSpace:Bool
    @ObservedObject var testMode: TestMode

//    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType) -> QuestionPartProtocol {
//        return IntervalAnswerView(contentSection:contentSection, score:score, answer: answer, testMode:testMode, questionType: questionType)
//    }
    
    init(contentSection:ContentSection, score:Score, answer:Answer, testMode:TestMode, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.answer = answer
        self.score = score
        self.testMode = testMode
        self.noteIsSpace = true //[Note.MIDDLE_C + 5, Note.MIDDLE_C + 9, Note.MIDDLE_C + 12, Note.MIDDLE_C + 16].contains(intervalNotes[0].midiNumber)
        metronome.speechEnabled = false
        self.questionType = questionType
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
    let id = UUID()
    //@State var refresh:Bool = false
    @ObservedObject var exampleData = ExampleData.shared
    var contentSection:ContentSection
    let parent:ContentSectionView
    @ObservedObject var testMode:TestMode

    //WARNING - Making Score a @STATE makes instance #1 of this struct pass its Score to instance #2
    var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
    @ObservedObject var answer: Answer = Answer()
    
    @ObservedObject var logger = Logger.logger
    @State var presentQuestionView:IntervalPresentView?
    @State var answerQuestionView:IntervalAnswerView?
    var questionType:QuestionType
    
//    func onRefresh() {
//        DispatchQueue.main.async {
//            refresh.toggle()
//        }
//    }
    
    init(questionType:QuestionType, contentSection:ContentSection, testMode:TestMode, parent:ContentSectionView) {
        self.contentSection = contentSection
        self.parent = parent
        self.testMode = testMode
        self.questionType = questionType
    }

    var body: some View {
        VStack {
            //Text("=============== \(testMode.mode == .exam ? "EXAM" : "PRACTICE") SUBMITTED STATE:\(answer.state == .submittedAnswer ? "YES" : "NOT")")
            if answer.state != .submittedAnswer {
                presentQuestionView
            }
            else {
                if testMode.mode == .practice {
                    answerQuestionView
                }
            }
            if answer.state == .submittedAnswer {
                VStack {
                    Button(action: {
                        parent.nextContentSection()
                    }) {
                        Text("Go to Next \(testMode.mode == .exam ? "Test" : "Example")").defaultStyle()
                    }
                }
                .padding()
            }
        }
        .background(UIGlobals.colorBackground)
        .onAppear {
            self.answer.setState(.notEverAnswered)
            presentQuestionView = IntervalPresentView(contentSection: contentSection,
                                                      score: self.score,
                                                      answer: answer,
                                                      testMode:testMode,
                                                      questionType:questionType)

            answerQuestionView = IntervalAnswerView(contentSection: contentSection,
                                                    score: score,
                                                    answer: answer,
                                                    testMode:testMode,
                                                    questionType:questionType)
        }

    }

}

