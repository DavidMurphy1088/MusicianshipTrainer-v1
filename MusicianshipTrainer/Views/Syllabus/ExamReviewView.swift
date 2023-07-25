import SwiftUI
import CoreData
import MessageUI

//https://www.istockphoto.com/illustrations/check-mark?servicecontext=srp-related

class Result: Identifiable {
    let id = UUID()
    var title: String
    var correct: Bool
    
    init(title: String, correct: Bool = true) {
        self.title = title
        self.correct = correct
    }
}

struct ExamReviewView: View {
    @State private var results = [
        Result(title: "Visual Interval 1"),
        Result(title: "Clapping"),
        Result(title: "Sight Reading"),
        Result(title: "Aural Interval 1", correct: false),
        Result(title: "Echo Clap"),
    ]

    var body: some View {
        Text("Your score for Exam 1 was 4 out of 5")
        Text("Here are the tests for the exam with your results -")
        VStack {
            List(results) { result in
                NavigationLink(destination: ResultDetailView(result: result)) {
                    HStack {
                        Text(result.title)
                            .padding()
                        Spacer()
                        Image(result.correct ? "correct" : "incorrect")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50.0)
                    }
                }
            }
            .navigationTitle("Results for Exam 1")
        }
    }
}

struct ResultDetailView: View {
    let result: Result

    var body: some View {
        Text(result.title)
            .font(.title)
            .navigationTitle(result.title)
            .padding()
        
    }
}
