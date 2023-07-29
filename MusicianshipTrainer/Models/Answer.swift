import Foundation

///The answer a student gives to a question
class Answer : ObservableObject, Identifiable {
    var id:UUID
    var correct: Bool = false
    var correctInterval = 0
    var correctIntervalName = ""
    var explanation = ""
    var selectedInterval:Int? = nil
    
    init() {
        id = UUID()
    }
    enum AnswerState {
        case notEverAnswered
        case notRecorded
        case recorded
        case recording
        case answered
        case submittedAnswer
    }
    
    @Published var state:AnswerState = .notEverAnswered

    func setState(ctx1:String, _ state:AnswerState) {
        DispatchQueue.main.async {
            //print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> answer set state, before:", ctx1, self.toString())
            self.state = state
            //print("                               >>>>> answer set state,  after:", ctx1, self.toString())

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

