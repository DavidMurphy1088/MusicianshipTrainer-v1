import SwiftUI
import WebKit

///A protocol that any view that instances a test view must comply with so that the user can navigate directly to the next test
//protocol NextNavigationView {
//    //var property: String { get set }
//    //func navigateNext()
//    //func hasNextPage() -> Bool
//    func enableNextNavigation() -> Bool
//}

struct ContentTypeView: View {

    let contentSection:ContentSection
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    
    var body: some View {
        VStack {
            //Text("----------- Content type VIEW --------------")
            let type = contentSection.type
           
            if type == "Type_1" {
                IntervalView(
                    questionType: QuestionType.intervalVisual,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_2" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmVisualClap,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_3" {
                ClapOrPlayView (
                    questionType: QuestionType.melodyPlay,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_4" {
                IntervalView(
                    questionType: QuestionType.intervalAural,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_5" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmEchoClap,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
        }
    }
}

struct ContentSectionTipsView: UIViewRepresentable {
    var htmlDocument:String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlDocument, baseURL: nil)
    }

}
   
struct ContentSectionInstructionsView: UIViewRepresentable {
    var htmlDocument:String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlDocument.trimmingCharacters(in: .whitespaces), baseURL: nil)
    }
}

struct ContentSectionHeaderView: View {
    var contentSection:ContentSection
    let googleAPI = GoogleAPI.shared
    @State private var isHelpPresented = false
    @State private var instructions:String? = nil
    @State private var tipsAndTricksExists = false
    @State private var tipsAndTricksData:String?=nil
    @State private var audioInstructionsFileName:String? = nil

    func getInstructions()  {
        let instructionContent = contentSection.getChildSectionByType(type: "Ins")
        if let instructionContent = instructionContent {
            if instructionContent.contentSectionData.data.count > 0 {
                let filename = instructionContent.contentSectionData.data[0]
                googleAPI.getDocumentByName(name: filename) {status,document in
                    if status == .success {
                        self.instructions = document
                    }
                }
            }
        }
    }
    
    func getTipsAndTricks()  {
        let tipsAndTricksContent = contentSection.getChildSectionByType(type: "T&T")
        if let tipsAndTricksContent = tipsAndTricksContent {
            if tipsAndTricksContent.contentSectionData.data.count > 0 {
                let filename = tipsAndTricksContent.contentSectionData.data[0]
                googleAPI.getDocumentByName(name: filename) {status,document in
                    if status == .success {
                        self.tipsAndTricksExists = true
                        self.tipsAndTricksData = document
                    }
                }
            }
        }
    }
    
    func getAudio()  {
        let audioContent = contentSection.getChildSectionByType(type: "Audio")
        if let audioContent = audioContent {
            if audioContent.contentSectionData.data.count > 0 {
                audioInstructionsFileName = audioContent.contentSectionData.data[0]
                
            }
        }
    }

    func getParagraphCount(html:String) -> Int {
        let p = html.components(separatedBy: "<p>").count
        return p - 1
    }
    
    var body: some View {
        VStack {
            Text("\(contentSection.getTitle())").font(.title)
                .fontWeight(.bold)
            
            VStack {
                if let audioInstructionsFileName = audioInstructionsFileName {
                    Button(action: {
                        AudioRecorder.shared.playAudioFromURL(urlString: audioInstructionsFileName)
                    }) {
                        Text("Aural Instructions").defaultStyle()
                    }
                    .padding()
                }

                if let instructions = self.instructions {
                    HStack {
                        //Spacer()
                        ContentSectionInstructionsView(htmlDocument: instructions)
                            .padding(.horizontal)
                            //.border(Color.black)
                            .padding(.horizontal)
                            .frame(height: getParagraphCount(html: instructions) < 2 ? 100 : 300)
                        //Spacer()
                    }
                }
            }
                   
            if tipsAndTricksExists {
                Button(action: {
                    isHelpPresented.toggle()
                }) {
                    HStack {
                        Text("Tips and Tricks")
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
                    }
                }
                .sheet(isPresented: $isHelpPresented) {
                    if let tipsAndTricksData = self.tipsAndTricksData {
                        ContentSectionTipsView(htmlDocument: tipsAndTricksData)
                            .padding()
                            .background(
                                Rectangle()
                                    .stroke(Color.blue, lineWidth: 4)
                            )
                    }
                }
            }
        }
        .onAppear() {
            getAudio()
            getInstructions()
            getTipsAndTricks()
        }
    }
}

struct SectionsNavigationView:View {
    let contentSections:[ContentSection]
    @State private var sectionIndex: Int?

    func getGradeImageName(contentSection: ContentSection) -> String? {
        if contentSection.isExamTypeContentSection() {
            if contentSection.questionStatus.status == 1 {
                if getScore(contentSection: contentSection) == contentSection.getNavigableChildSections().count {
                    return "grade_a"
                }
                else {
                    return "grade_b"
                }
            }
            else {
                return nil
            }
        }
        else {
            if let answer = contentSection.answer11 {
                if answer.correct {
                    return "grade_a"
                }
                else {
                    return "grade_b"
                }
            }
            else {
                return nil
            }
        }
    }
    
    func getScore(contentSection: ContentSection) -> Int {
        var score = 0
        for s in contentSection.getNavigableChildSections() {
            if let answer = s.answer11 {
                if answer.correct {
                    score += 1
                }
            }
        }
        return score
    }
    
    func getExamCompleteStatus(contentSection: ContentSection) -> String {
        if contentSection.isExamTypeContentSection() {
            if contentSection.questionStatus.status == 1 {
                return "Completed - \(getScore(contentSection: contentSection)) out of \(contentSection.getNavigableChildSections().count)"
            }
            else {
                return "Not Started"
            }
        }
        return ""
    }

    var body: some View {
        VStack {
            List(Array(contentSections.indices), id: \.self) { index in
                ///- selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`.
                NavigationLink(destination: ContentSectionView(contentSection: contentSections[index]),
                               tag: index,
                               selection: $sectionIndex) {

                    HStack {
                        Text(contentSections[index].getTitle()).padding().font(.title2)
                        Spacer()
                        HStack {
                            Spacer()
                            Text(self.getExamCompleteStatus(contentSection: contentSections[index])).padding().font(.title2)
                            //Text("Status:[\(contentSections[index].questionStatus.status)]")
                            if let imageName = getGradeImageName(contentSection: contentSections[index]) {
                                Spacer()
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40.0)
                                Text("    ")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ExamView: View {
    let contentSection:ContentSection
    let contentSections:[ContentSection]
    @State var sectionIndex = 0
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer = Answer(ctx: "ExamView", questionMode: .examTake)
    
    init(contentSection:ContentSection, contentSections:[ContentSection]) {
        self.contentSection = contentSection
        self.contentSections = contentSections
    }
    
    func showAnswer() -> Int {
        print ("Ans====", answer.correct)
        return answer.correct ? 1 : 0
    }
    
    func copyAnwser(_ ans:Answer) -> Answer {
        var a = Answer(ctx: "copy", questionMode: ans.questionMode)
        a.correct = ans.correct
        a.selectedInterval = ans.selectedInterval
        a.correctInterval = ans.correctInterval
        a.correctIntervalName = ans.correctIntervalName
        a.explanation = ans.explanation
        return a
    }
    
    var body: some View {
        VStack {

            if self.answerState == .submittedAnswer {
                Spacer()
                Text("++++++++++ Submitted ++++++++++ \(showAnswer())").font(.title)
                Spacer()
                if sectionIndex < contentSections.count - 1 {
                    Button(action: {
                        answerState = .notEverAnswered
                        contentSections[sectionIndex].answer11 = copyAnwser(answer)
                        sectionIndex += 1
                    }) {
                        Text("Go to next Exam Question Index:\(sectionIndex) count:\(contentSections.count)").font(.title)
                    }
                }
                else {
                    Spacer()
                    Text("+++++++++++ END OF EXAM ++++++++++++++")
                    Button(action: {
                        contentSections[sectionIndex].answer11 = copyAnwser(answer)
                        contentSection.questionStatus.setStatus(1)

                    }) {
                        Text("END EXAM ....").font(.title)
                    }

                    Spacer()
                }
                Spacer()
            }
            else {
                ContentTypeView(contentSection: contentSections[sectionIndex], answerState: $answerState, answer: $answer)
            }
        }
        .onAppear() {
            self.sectionIndex = 0            
        }
    }
}

struct ContentSectionView: View {
    @State private var selectedContentIndex: Int?
    @State private var showNextNavigation: Bool = true
    @State private var endOfSection: Bool = false
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer(ctx: "ContentSectionView", questionMode: .practice)
    @State var sectionIndex:Int = 0
    
    let id = UUID()
    let contentSection:ContentSection

//    init(contentSection:ContentSection) {
//        self.contentSection = contentSection
//    }
//
    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            if childSections.count > 0 {
                
                ContentSectionHeaderView(contentSection: contentSection)
                
                if contentSection.isExamTypeContentSection() && contentSection.hasNoAnswers() {
                    ExamView(contentSection: contentSection, contentSections: childSections)
                }
                else {
                    SectionsNavigationView(contentSections: childSections)
                }
            }
            else {
                ContentTypeView(contentSection: self.contentSection, answerState: $answerState, answer: $answer)
            }
            
        }
        .onAppear {
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }
}

