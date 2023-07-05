import SwiftUI

//All question presentations and answers follow this protocol
protocol QuestionPartProtocol {
    var body: AnyView { get }
    init(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode, refresh: (() -> Void)?)
    static func createInstance(contentSection:ContentSection, score:Score, answer:Answer, mode:QuestionMode) -> QuestionPartProtocol
}

// the answer a student gives to a question
class Answer : ObservableObject {
    //Bad Idea shared since all questions then share the same answered state BAD
    //static var shared = Answer()
    
    var correct: Bool = false
    var correctInterval = 0
    var correctIntervalName = ""
    var explanation = ""
    var selectedInterval:Int? = nil
    
    @Published private var internalState:AnswerState = .notEverAnswered
    
    enum AnswerState {
        case notEverAnswered
        case notRecorded
        case recorded
        case recording
        case answered
        case submittedAnswer
    }
    
    func setState(_ state:AnswerState) {
        DispatchQueue.main.async {
            self.internalState = state
        }
    }
    
    public var state: AnswerState {
        get {
            return internalState
        }
    }
}
