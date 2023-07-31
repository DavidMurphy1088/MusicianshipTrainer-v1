import Foundation

enum AnswerState {
    case notEverAnswered
    case notRecorded
    case recorded
    case recording
    case answered
    case submittedAnswer
}

///The answer a student gives to a question
class Answer : Identifiable {
    var id:UUID
    var correct: Bool = false
    var correctInterval = 0
    var correctIntervalName = ""
    var explanation = ""
    var selectedInterval:Int? = nil
    var questionMode: QuestionMode
    
    init(ctx:String, questionMode:QuestionMode) {
        id = UUID()
        self.questionMode = questionMode
    }
    
}

