import SwiftUI
import WebKit

struct ContentTypeView: View {

    let contentSection:ContentSection
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    
    func isNavigationHidden() -> Bool {
        if let parent = contentSection.parent {
            if parent.isExamTypeContentSection() && contentSection.answer11 == nil {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
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
        .navigationBarHidden(isNavigationHidden())
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
                        ContentSectionInstructionsView(htmlDocument: instructions)
                            .frame(height: CGFloat(getParagraphCount(html: instructions)) * 150.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                            )
                            .padding()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
            )
            .background(UIGlobals.colorScore)
            .padding(.horizontal)
               
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
    @Environment(\.presentationMode) var presentationMode
    let contentSection:ContentSection
    let contentSections:[ContentSection]
    @State var sectionIndex = 0
    @State var examBeginning = true
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer = Answer(ctx: "ExamView")//, questionMode: .examTake)
    
    init(contentSection:ContentSection, contentSections:[ContentSection]) {
        self.contentSection = contentSection
        self.contentSections = contentSections
    }
    
    func showAnswer() -> Int {
        print ("Ans====", answer.correct)
        return answer.correct ? 1 : 0
    }
    
    func isNavigationHidden() -> Bool {
        if examBeginning {
            return false
        }
        else {
            return contentSection.isExamTypeContentSection()
        }
    }

    var body: some View {
        VStack {
            if examBeginning {
                if let parent = contentSection.parentWithInstructions() {
                    ContentSectionHeaderView(contentSection: parent)
                    Spacer()
                    Button(action: {
                        self.examBeginning = false
                    }) {
                        Text("Start the Exam").defaultStyle()
                    }
                    Spacer()
                }
            }
            else {
                if self.answerState == .submittedAnswer {
                    Spacer()
                    if sectionIndex < contentSections.count - 1 {
                        Text("Completed question \(sectionIndex+1) of \(contentSections.count)").padding()
                        Button(action: {
                            answerState = .notEverAnswered
                            contentSections[sectionIndex].answer11 = answer.copyAnwser()
                            sectionIndex += 1
                        }) {
                            VStack {
                                Text("Go to the next exam question").defaultStyle().padding()
                            }
                        }
                    }
                    else {
                        Spacer()
                        Button(action: {
                            contentSections[sectionIndex].answer11 = answer.copyAnwser()
                            contentSection.questionStatus.setStatus(1)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("End of Exam").defaultStyle()
                            
                        }
                        Spacer()
                    }
                    Spacer()
                }
                else {
                    ContentTypeView(contentSection: contentSections[sectionIndex], answerState: $answerState, answer: $answer)
                }
            }
        }
        .navigationBarHidden(isNavigationHidden())
        .onAppear() {
            self.sectionIndex = 0            
        }
    }
}

struct ContentSectionView: View {
    let contentSection:ContentSection
    @State private var selectedContentIndex: Int?
    @State private var showNextNavigation: Bool = true
    @State private var endOfSection: Bool = false
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer(ctx: "ContentSectionView")//, questionMode: .practice)
    @State var sectionIndex:Int = 0
    
    let id = UUID()
    
    init (contentSection:ContentSection) {
        self.contentSection = contentSection
        //self.selectedContentIndex = selectedContentIndex
    }
    
    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            if childSections.count > 0 {
                if contentSection.isExamTypeContentSection() {
                    //No ContentSectionHeaderView in any exam mode content section except the exam start
                    if contentSection.hasExamModeChildren() {
                        SectionsNavigationView(contentSections: childSections)
                    }
                    else {
                        if contentSection.hasNoAnswers() {
                            ExamView(contentSection: contentSection, contentSections: childSections)
                        }
                        else {
                            //Exam was taken
                            SectionsNavigationView(contentSections: childSections)
                        }
                    }
                }
                else {
                    ContentSectionHeaderView(contentSection: contentSection)
                    SectionsNavigationView(contentSections: childSections)
                }
            }
            else {
                ContentTypeView(contentSection: self.contentSection, answerState: $answerState, answer: $answer)
            }
            
        }
        .onAppear {
            if contentSection.answer11 != nil {
                print("ContentSectionView ==== did set answer submitted", answerState)
                self.answerState = .submittedAnswer
                self.answer = contentSection.answer11!
            }
            else {
                print("ContentSectionView ==== did NOT set answer submitted", answerState)
            }
            
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }
}

