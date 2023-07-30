//import SwiftUI
//import CoreData
//import MessageUI
//import AVFoundation
//
////https://www.istockphoto.com/illustrations/check-mark?servicecontext=srp-related
////https://www.shutterstock.com/image-vector/iconic-illustration-satisfaction-level-range-assess-366844406
//
//class Result: Identifiable {
//    enum ResultType {
//        case notAnswered
//        case correct
//        case incorrect
//        
//    }
//    let id = UUID()
//    var title: String
//    var correct: Bool
//    var answered: Bool
//    
//    init(title: String, correct: Bool = true, answered: Bool) {
//        self.title = title
//        self.correct = correct
//        self.answered = answered
//    }
//}
//
//struct ExamView: View, NextNavigationView {
//    func enableNextNavigation() -> Bool {
//        return false
//    }
//    
//    func showNext() -> Bool {
//        return true
//    }
//    
//    let contentSection:ContentSection
//    let result:Result = Result(title: "", answered: false)
//    @State var testInt:Int?=0
//    let googleAPI = GoogleAPI.shared
//    @State var testIndex:Int? = nil
//    @State var contentSections:[ContentSection] = []
//    @State private var instructions:String? = nil
//    @State private var audioInstructionsFileName:String? = nil
//
//    init(contentSection:ContentSection) {
//        self.contentSection = contentSection
//    }
//    
//    func navigateNext() {
//        if self.testIndex != nil {
//            self.testIndex! += 1
//        }
//    }
//    
//    func hasNextPage() -> Bool {
//        if let index = self.testIndex {
//            return index < self.contentSection.subSections.count - 1
//        }
//        return true
//    }
//    
//    func getInstructions()  {
//        let instructionContent = contentSection.getChildSectionByType(type: "Ins")
//        if let instructionContent = instructionContent {
//            if instructionContent.contentSectionData.data.count > 0 {
//                let filename = instructionContent.contentSectionData.data[0]
//                googleAPI.getDocumentByName(name: filename) {status,document in
//                    if status == .success {
//                        self.instructions = document
//                    }
//                }
//            }
//        }
//    }
//    
//    func getAudio()  {
//        let audioContent = contentSection.getChildSectionByType(type: "Audio")
//        if let audioContent = audioContent {
//            if audioContent.contentSectionData.data.count > 0 {
//                audioInstructionsFileName = audioContent.contentSectionData.data[0]
//            }
//        }
//    }
//    
//    func examBeginView() -> some View {
//        VStack {
//            Text("Start of Exam").padding()
//
//            if let instructions = self.instructions {
//                ContentSectionInstructionsView(htmlDocument: instructions)
//                    .padding(.horizontal)
//                //.border(Color.black)
//                    .padding(.horizontal)
//                //.frame(height: getParagraphCount(html: instructions) < 2 ? 100 : 300)
//            }
//
//            if let audioInstructionsFileName = audioInstructionsFileName {
//                Button(action: {
//                    AudioRecorder.shared.playAudioFromURL(urlString: audioInstructionsFileName)
//                }) {
//                    Text("Aural Instructions").defaultStyle()
//                }
//                .padding()
//            }
//
//            Button(action: {
//                if self.testIndex == nil {
//                    self.testIndex = 0
//                }
//                else {
//                    self.testIndex! += 1
//                }
//            }) {
//                Text("Start the Exam").defaultStyle()
//            }
//            .padding()
//            Spacer()
//        }
//    }
//    
//    func examEndView() -> some View {
//        VStack {
//            Text("End of exam").padding()
//            Text("Some instructions....").padding()
//        }
//    }
//
//    var body: some View {
//        VStack {
//            Text("Exam view...")
//        }
//    }
////    var body1: some View {
////        VStack {
////            if self.testIndex == nil {
////                examBeginView()
////            }
////            else {
////                if self.testIndex! >= self.contentSections.count {
////                    examEndView()
////                }
////                else {
////                    VStack {
////                        let testContentSection = self.contentSections[self.testIndex!]
////                        let testType = testContentSection.type
////                        let answer = Answer(ctx: "Exam View")
////                        //Text("===== TEST INDEX \(testIndex == nil ? "" : String(testIndex!)) Content:\(testContentSection.name)")
////                        
////                        switch testType {
////                        case "Type_1":
////                            IntervalView(questionType: .intervalVisual,
////                                         contentSection: testContentSection,
////                                         nextNavigationView: self
////                                         //answer: answer
////                            )
////                        case "Type_2":
////                            ClapOrPlayView(questionType: .rhythmVisualClap,
////                                           contentSection: testContentSection,
////                                           nextNavigationView: self
////                                           //answer: answer
////                            )
////                        case "Type_3":
////                            ClapOrPlayView(questionType: .melodyPlay,
////                                           contentSection: testContentSection,
////                                           nextNavigationView: self,
////                                           answer: answer
////                            )
////                        case "Type_4" :
////                            IntervalView(questionType: .intervalAural,
////                                         contentSection: testContentSection,
////                                         nextNavigationView: self,
////                                         answer: answer
////                            )
////                        case "Type_5":
////                            ClapOrPlayView(questionType: .rhythmEchoClap,
////                                           contentSection: testContentSection,
////                                           nextNavigationView: self,
////                                           answer: answer
////                            )
////                            
////                        default:
////                            VStack {
////                                Text("Unknown test.")
////                            }
////                        }
////                    }
////                }
////            }
////        }
////        .onAppear() {
////            for section in contentSection.subSections {
////                if section.isQuestionType() {
////                    contentSections.append(section)
////                }
////            }
////            self.getAudio()
////            self.getInstructions()
////        }
////    }
//
//}
