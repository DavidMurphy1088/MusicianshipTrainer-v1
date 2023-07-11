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

struct IntervalPresentView: View, QuestionPartProtocol {
    @ObservedObject var answer:Answer
    var score:Score
    let exampleData = ExampleData.shared
    var intervalNotes:[Note] = []
    @ObservedObject private var logger = Logger.logger
    @State private var selectedIntervalIndex:Int = 10//? = nil
    var mode:QuestionMode
    let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"IntervalPresentView")
    @State private var selectedOption: String? = nil
    @State private var scoreWasPlayed = false
    
    class IntervalName : Hashable {
        var interval: Int
        var name:String
        var explanation:[String]
        var isIncluded = true
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
    
    let intervals = [IntervalName(interval:2, name: "Second",
                                  //explanation: ["A line to a space is a step which is a second interval",
                                  //              "A space to a line is a step which is a second interval"]),
                                  explanation: ["A line to a space is a step",
                                                "A space to a line is a step"]),
                     IntervalName(interval:3, name: "Third",
                                explanation: ["A line to a line is a skip",
                                              "A space to a space is a skip"]),
                     IntervalName(interval:4, name: "Third",
                                explanation: ["",""]),
    ]
    
    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode) -> QuestionPartProtocol {
        return IntervalPresentView(contentSection: contentSection, score:score, answer: answer, mode:mode)
    }
    
    init(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode, refresh:(() -> Void)? = nil) {
        self.answer = answer
        self.score = score
        self.mode = mode
        let exampleData = exampleData.get(contentSection: contentSection) //contentSection.parent!.name, contentSection.name, exampleKey: contentSection.gr)
        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
        
        self.score.setStaff(num: 0, staff: staff)
        let chord:Chord = Chord()
        if let entries = exampleData {
            for entry in entries {
                if entry is Note {
                    let timeSlice = self.score.addTimeSlice()
                    let note = entry as! Note
                    timeSlice.addNote(n: note)
                    intervalNotes.append(note)
                    if mode == .intervalAural {
                        chord.addNote(note: Note(num: note.midiNumber, value: 2))
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
            if interval.interval == 3 {
                interval.isIncluded = mode == .intervalVisual
            }
            if interval.interval == 4 {
                interval.isIncluded = mode == .intervalAural
            }
        }
    }
    
    var selectIntervalView : some View {
        HStack(spacing: 0) {
            ForEach(Array(intervals.enumerated()), id: \.1) { index, interval in
                if interval.isIncluded {
                    Button(action: {
                        selectedIntervalIndex = index
                        answer.setState(.answered)
                        answer.selectedInterval = intervals[index].interval
                    }) {
                        Text(interval.name)
                        //.foregroundColor(.white)
                            .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(scoreWasPlayed ? Color.black : Color.clear, lineWidth: 1)
                                    .background(selectedIntervalIndex == index ? Color(.systemTeal) : Color.clear)
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
                if mode == .intervalVisual {
                    ScoreSpacerView()
//<<<<<<< HEAD
                    ScoreSpacerView()
                    ScoreView(score: score).padding()
                    ScoreSpacerView()
                    ScoreSpacerView()
//=======
                    //ScoreView(score: score).padding()
                    ScoreSpacerView()
//>>>>>>> main
                }
                
                HStack {
                    if mode != .intervalVisual {
                        Button(action: {
                            metronome.playScore(score: score, onDone: {
                                self.scoreWasPlayed = true
                            })
                            self.scoreWasPlayed = true
                        }) {
                            Text("Hear Interval")
                                .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
                        }
                        .padding()
                        .background(UIGlobals.backgroundColor)
                        .padding()
                    }
                }
                VStack {
                    Text("Is the interval a second or a third?").padding()
                    VStack {
                        selectIntervalView.padding()
                    }
                    .padding()
                }
                .disabled(mode == .intervalAural && scoreWasPlayed == false)
                
                VStack {
                    if answer.state == .answered {
                        Button(action: {
                            answer.setState(.submittedAnswer)
                            let interval = abs((intervalNotes[1].midiNumber - intervalNotes[0].midiNumber))
                            if answer.selectedInterval == interval {
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
                        }) {
                            Text("Check Your Answer")
                                .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
                        }
                        .padding()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                )
                .background(UIGlobals.backgroundColor)
                .padding()
                Spacer()
//                if logger.status.count > 0 {
//                    Text(logger.status).foregroundColor(logger.isError ? .red : .gray)
                //}
            }
        )
    }
}

struct IntervalAnswerView: View, QuestionPartProtocol {
    @ObservedObject var answer:Answer
    private var mode:QuestionMode

    private var score:Score
    private let imageSize = Double(32)
    private let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"Interval answer View")
    private var noteIsSpace:Bool
    
    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode) -> QuestionPartProtocol {
        return IntervalAnswerView(contentSection:contentSection, score:score, answer: answer, mode: mode)
    }
    
    init(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode, refresh:(() -> Void)? = nil) {
        self.answer = answer
        self.score = score
        self.noteIsSpace = true //[Note.MIDDLE_C + 5, Note.MIDDLE_C + 9, Note.MIDDLE_C + 12, Note.MIDDLE_C + 16].contains(intervalNotes[0].midiNumber)
        metronome.speechEnabled = false
        self.mode = mode
    }
    
    var body: AnyView {
        AnyView(
            VStack {
                ScoreSpacerView()
//<<<<<<< HEAD
                //ScoreSpacerView()
                ScoreView(score: score).padding()
                ScoreSpacerView()
                //ScoreSpacerView()
//=======
                //ScoreView(score: score).padding()
                ScoreSpacerView()
//>>>>>>> main
                
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
                if mode == .intervalVisual {
                    Text(answer.explanation).italic().fixedSize(horizontal: false, vertical: true).padding()
                }
                
                if mode == .intervalAural {
                    Button(action: {
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval")
                            .foregroundColor(.white).padding().background(Color.blue).cornerRadius(UIGlobals.cornerRadius).padding()
                    }
                    .padding()
                }
                
                Spacer()
            }
//            .overlay(
//                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
//            )
//            .background(UIGlobals.backgroundColor)
//            .padding()
        )
    }
}

struct IntervalView: View {
    let id = UUID()
    @State var refresh:Bool = false
    @ObservedObject var exampleData = ExampleData.shared
    var contentSection:ContentSection
    //WARNING - Making Score a @STATE makes instance #1 of this struct pass its Score to instance #2
    var score:Score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
    @ObservedObject var answer: Answer = Answer()
    @ObservedObject var logger = Logger.logger
    var presentQuestionView:IntervalPresentView?
    var answerQuestionView:IntervalAnswerView?
    
    func onRefresh() {
        DispatchQueue.main.async {
            refresh.toggle()
        }
    }
    
    init(mode:QuestionMode, contentSection:ContentSection) {
        self.contentSection = contentSection
        presentQuestionView = IntervalPresentView(contentSection: contentSection, score: self.score, answer: answer, mode:mode)
        answerQuestionView = IntervalAnswerView(contentSection: contentSection, score: score, answer: answer, mode:mode, refresh: onRefresh)
    }

    var body: some View {
        VStack {
            if answer.state != .submittedAnswer {
                presentQuestionView
            }
            else {
                answerQuestionView
            }
            if let errMsg = logger.errorMsg {
                Text(errMsg)
            }
        }
    }
}

