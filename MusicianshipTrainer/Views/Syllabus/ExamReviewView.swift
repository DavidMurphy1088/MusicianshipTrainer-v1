import SwiftUI
import CoreData
import MessageUI

//https://www.istockphoto.com/illustrations/check-mark?servicecontext=srp-related
//https://www.shutterstock.com/image-vector/iconic-illustration-satisfaction-level-range-assess-366844406

class Result: Identifiable {
    let id = UUID()
    var title: String
    var correct: Bool
    
    init(title: String, correct: Bool = true) {
        self.title = title
        self.correct = correct
    }
}

struct ExamView: View, NextNavigationView {
    let contentSection:ContentSection
    @State var testInt:Int?=0
    //@State var ans = Answer()
    
    @State private var results = [
        Result(title: "Visual Interval 1"),
        Result(title: "Clapping"),
        Result(title: "Sight Reading"),
        Result(title: "Aural Interval 1", correct: false),
        Result(title: "Echo Clap"),
    ]
    @State var testIndex:Int? = nil

//    var body1: some View {
//        Text("Your score for Exam 1 was 4 out of 5")
//        Text("Here are the tests for the exam with your results -")
//        VStack {
//            List(results) { result in
//                NavigationLink(destination: ResultDetailView(result: result)) {
//                    HStack {
//                        Text(result.title)
//                            .padding()
//                        Spacer()
//                        Image(result.correct ? "correct" : "incorrect")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 50.0)
//                    }
//                }
//            }
//            .navigationTitle("Results for Exam 1")
//        }
//    }
    func navigateNext() {
        if self.testIndex != nil {
            self.testIndex! += 1
        }
        print ("=============== EamView Nav next ", self.testIndex)
    }

    func examBeginView() -> some View {
        VStack {
            Text("Start of exam")
            
            Button(action: {
                if self.testIndex == nil {
                    self.testIndex = 0
                }
                else {
                    self.testIndex! += 1
                }
            }) {
                Text("Start the Exam").defaultStyle()
            }
        }
    }
    
    var body: some View {
        VStack {
            if self.testIndex == nil {
                examBeginView()
            }
            else {VStack {
                let testContentSection = self.contentSection.subSections[self.testIndex!]
                let testType = testContentSection.type
                Text("===== TEST INDEX \(testIndex == nil ? "" : String(testIndex!)) Content:\(testContentSection.name)")

                switch testType {
                case "Type.1":
                    IntervalView(questionType: .intervalVisual,
                                 contentSection: testContentSection,
                                 testMode: TestMode(mode: .exam),
                                 nextNavigationView: self,
                                 answer: Answer())
                case "Type.2":
                    ClapOrPlayView(questionType: .intervalVisual,
                                   contentSection: testContentSection,
                                   testMode: TestMode(mode: .exam),
                                   nextNavigationView: self
                                   //Answer()
                    )
                default:
                    VStack {
                        Text("Unknown test.")
                    }
                }
            }
            }
        }
        .onAppear() {
            //loadContentSections()
        }
    }

}

