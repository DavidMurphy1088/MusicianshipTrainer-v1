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
class Answer : ObservableObject, Identifiable {
    var id:UUID
    var correct: Bool = false
    var correctInterval = 0
    var correctIntervalName = ""
    var explanation = ""
    var selectedInterval:Int? = nil
    @Published var state:AnswerState = .notEverAnswered

    init(ctx:String) {
        id = UUID()
        //print("\n----------------------------->>>>> answer INIT::", "context:[\(ctx)]", "Self[:\(self.toString())]")
    }
    
    func setState(_ newState:AnswerState) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }

//    public var state: AnswerState {
//        get {
//            return internalState
//        }
//    }
    
    func toString() -> String {
        var s = ""
        switch self.state {
        case .notEverAnswered:
            s = "notEverAnswered"
        case .answered:
            s = "answered"
        case .submittedAnswer:
            s = "submittedAnswer"
        default:
            s = "other..."
        }
        let id = id.uuidString.suffix((4))
        return id + " " + s
    }
}

