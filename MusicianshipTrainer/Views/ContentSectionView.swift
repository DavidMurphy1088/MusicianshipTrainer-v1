import SwiftUI
import WebKit

struct ContentTypeView: View {
    let contentSection:ContentSection
    @Binding var answerState:AnswerState
    
    @Binding var answer:Answer

    func isNavigationHidden() -> Bool {
        ///No exit navigation in exam mode
        if let parent = contentSection.parent {
            if parent.isExamTypeContentSection() && contentSection.answer111 == nil {
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

struct NarrationView : View {
    let contentSection:ContentSection
    let htmlDocument:String
    let context:String
    
    var body: some View {
        VStack {
            HStack {
                
                Button(action: {
                    TTS.shared.speakText(contentSection: contentSection, context: context, htmlContent: htmlDocument)
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                        .padding()
                }
                Spacer()
            }
            Spacer()
        }
        .onDisappear() {
            TTS.shared.stop()
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
    //@Binding var parentSelectionIndex:Int?
    var parentSelection: SectionsNavigationView

    let googleAPI = GoogleAPI.shared
    @State private var isTipsTricksPresented = false
    @State private var instructions:String? = nil
    @State private var tipsAndTricksExists = false
    @State private var tipsAndTricksData:String?=nil
    @State private var audioInstructionsFileName:String? = nil
    
    init (contentSection:ContentSection, parentSelection:SectionsNavigationView) {
        self.contentSection = contentSection
        self.parentSelection = parentSelection
        //_parentSelectionIndex = parentSelectionIndex
    }
    
    func getInstructions()  {
        var pathSegments = contentSection.getPathAsArray()
        if pathSegments.count < 1 {
            return
        }
        let filename = "Instructions" //instructionContent.contentSectionData.data[0]
        pathSegments.append(UIGlobals.getAgeGrpup())
        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false) {status,document in
            if status == .success {
                self.instructions = document
            }
        }
    }
    
    func getTipsAndTricks()  {
        let filename = "Tips_Tricks" //tipsAndTricksContent.contentSectionData.data[0]
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(UIGlobals.getAgeGrpup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false) {status,document in
            if status == .success {
                self.tipsAndTricksExists = true
                self.tipsAndTricksData = document
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
        var p = html.components(separatedBy: "<p>").count
        if p > 4 {
            p = 4
        }
        return p
    }
    
    func log(contentSection: ContentSection, index:Int?) -> Bool {
        print(contentSection.getPathTitle(), "index", index)
        return true
    }
    
//    func randomSelection() -> some View {
//        VStack {
////            if log(contentSection: contentSection) {
////                ContentTypeView(contentSection: contentSection.subSections[2],
////                                answerState: $answerState,
////                                answer: $answer)
////            }
//        }
//    }
    
    var body: some View {
//        if random {
//            randomSelection()
//        }
//        else {
            prompts()
//        }
    }

    func prompts() -> some View {
        VStack {
            VStack {
                if let audioInstructionsFileName = audioInstructionsFileName {
                    Button(action: {
                        AudioRecorder.shared.playAudioFromCloudURL(urlString: audioInstructionsFileName)
                    }) {
                        Text("Aural Instructions").defaultButtonStyle()
                    }
                    .padding()
                }
                
                if let instructions = self.instructions {
                    HStack {
                        ZStack {
                            ContentSectionInstructionsView(htmlDocument: instructions)
                            NarrationView(contentSection: contentSection, htmlDocument: instructions, context: "Instructions")
                        }
                        .frame(height: CGFloat((getParagraphCount(html: instructions)))/12.0 * UIScreen.main.bounds.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                        )
                        .padding()
                        //.background(UIGlobals.colorNavigationBackground)
                        .background(Color(.secondarySystemBackground))
                    }
                }
            }
               
            if tipsAndTricksExists {
                HStack {
                    Spacer()
                    Button(action: {
                        isTipsTricksPresented.toggle()
                    }) {
                        VStack {
                            HStack {
                                Text("Tips and Tricks").font(UIGlobals.navigationFont)
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .sheet(isPresented: $isTipsTricksPresented) {
                        if let tipsAndTricksData = self.tipsAndTricksData {
                            ZStack {
                                ContentSectionTipsView(htmlDocument: tipsAndTricksData)
                                    .background(Rectangle().stroke(Color.blue, lineWidth: 4))
                                NarrationView(contentSection: contentSection, htmlDocument: tipsAndTricksData, context: "TipsTricks")
                            }
                            .padding()
                            .background(
                                Rectangle().stroke(Color.blue, lineWidth: 4)
                            )
                        }
                    }
                    Spacer()
                    Button(action: {
                        //randomSelection()
                        DispatchQueue.main.async {
                            //log(contentSection: contentSection, index: parentSelectionIndex)
                            //parentSelectionIndex = 2
                            //parentSelection.sectionIndex = 2
                            parentSelection.test(index: 2)
                        }
                        //random = true
                    }) {
                        VStack {
                            HStack {
                                Text("Random Pick").font(UIGlobals.navigationFont)
                                Image(systemName: "tornado")
                                    .foregroundColor(.blue)
                                    .font(.largeTitle)
                            }
                        }
                    }
//                    .sheet(isPresented: $random) {
//                        randomSelection()
//                    }

                    Spacer()
                }
            }
        }
        .onAppear() {
            getAudio()
            getInstructions()
            getTipsAndTricks()
        }
        .onDisappear() {
            TTS.shared.stop()
        }
    }
}

struct SectionsNavigationView:View {
    let contentSections:[ContentSection]
    @State var sectionIndex: Int?
    
    func test(index:Int) {
        sectionIndex = index
    }
    
    func getGradeImage(contentSection: ContentSection) -> Image? {
        var name = ""
        if contentSection.isExamTypeContentSection() {
            //test section group header
            if contentSection.hasNoAnswers() {
                return nil
            }
            else {
                if getScore(contentSection: contentSection) == contentSection.getNavigableChildSections().count {
                    name = "checkmark_ok" //grade_a"
                }
                else {
                    name = "checkmark_ok" //grade_b"
                }
            }
        }
        else {
            //individual tests
            if let answer = contentSection.answer111 {
                if answer.correct {
                    name = "grade_a"
                }
                else {
                    name = "grade_b"
                }
            }
            else {
                return nil
            }
        }
        var image:Image
        image = Image(name)
        return image
    }
    
    func getScore(contentSection: ContentSection) -> Int {
        var score = 0
        for s in contentSection.getNavigableChildSections() {
            if let answer = s.answer111 {
                if answer.correct {
                    score += 1
                }
            }
        }
        return score
    }
    
    func getExamCompleteStatus(contentSection: ContentSection) -> String {
        if contentSection.isExamTypeContentSection() {
            if contentSection.hasNoAnswers() {
                return "Not Started"
            }
            else {
                return "Completed - \(getScore(contentSection: contentSection)) out of \(contentSection.getNavigableChildSections().count)"
            }
        }
        return ""
    }

    var body: some View {
        VStack {
            List(Array(contentSections.indices), id: \.self) { index in
                ///selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`
                ///tag: The value of `selection` that causes the link to present `destination`..
                NavigationLink(destination:
                                ContentSectionView(contentSection: contentSections[index],
                                                   parentSelectionIndex: $sectionIndex),
                               tag: index,
                               selection: $sectionIndex) {

                    ZStack {
                        HStack {
                            Spacer()
                            Text(contentSections[index].getTitle())
                                .font(UIGlobals.navigationFont)
                                .padding(.vertical, 8) //xxxx
                            Spacer()
                            if let rowImage = getGradeImage(contentSection: contentSections[index]) {
                                HStack {
                                    Spacer()
                                    rowImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40.0)
                                    Text("    ")
                                }
                            }
                        }
                        ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                        HStack {
                            Text("")
                            Spacer()
                        }

                    }
                    //.border(Color.green)
                }
                //.listRowBackground(UIGlobals.colorNavigation)
                //.listRowBackground(Color(.systemBackground))
                //.background(UIGlobals.colorNavigation)

                ///This color matches the NavigationView background which cannot be changed.
                ///i.e. any other colour here causes the navigation link rows to have a different background than the background of the navigationView's own background
                .listRowBackground(Color(.secondarySystemBackground))
                ///Does nothing :(
                //.padding(.vertical, 0)
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
    @State private var showingConfirm = false
    
    init(contentSection:ContentSection, contentSections:[ContentSection]) {
        self.contentSection = contentSection
        self.contentSections = contentSections
    }
    
    func showAnswer() -> Int {
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
                //if let parent = contentSection.parentWithInstructions() {
                    //ContentSectionHeaderView(contentSection: parent)
                    Spacer()
                    Button(action: {
                        self.examBeginning = false
                    }) {
                        VStack {
                            Text("The exam has \(contentSections.count) questions").defaultTextStyle().padding()
                            Text("Start the Exam").defaultButtonStyle()
                        }
                    }
                    Spacer()
                //}
            }
            else {
                if self.answerState == .submittedAnswer {
                    Spacer()
                    if sectionIndex < contentSections.count - 1 {
                        Text("Completed question \(sectionIndex+1) of \(contentSections.count)").defaultTextStyle().padding()
                        Button(action: {
                            contentSections[sectionIndex].answer111 = answer.copyAnwser()
                            contentSections[sectionIndex].storeAnswer(answer: answer.copyAnwser())
                            answerState = .notEverAnswered
                            sectionIndex += 1
                        }) {
                            VStack {
                                Text("Next Exam Question").defaultButtonStyle()
                            }
                        }
                        .padding()
                        Spacer()
                        Button(action: {
                            //contentSections[sectionIndex].saveAnswer(answer: answer.copyAnwser())
                            //contentSection.questionStatus.setStatus(1)
                            //presentationMode.wrappedValue.dismiss()
                            showingConfirm = true
                        }) {
                            VStack {
                                Text("Exit Exam").defaultButtonStyle().padding()
                            }
                        }
                        .alert(isPresented: $showingConfirm) {
                            Alert(title: Text("Are you sure?"),
                                  message: Text("You cannot restart an exam you exit from"),
                                  primaryButton: .destructive(Text("Yes, I'm sure")) {
                                for s in contentSections {
                                    //if s.answer111 == nil {
                                        let answer = Answer(ctx: "cancelled")
                                        s.answer111 = answer
                                        s.storeAnswer(answer: answer)
                                    //}
                                }
                                presentationMode.wrappedValue.dismiss()
                            }, secondaryButton: .cancel())
                        }
                        .padding()

                    }
                    else {
                        Spacer()
                        Button(action: {
                            contentSections[sectionIndex].answer111 = answer.copyAnwser()
                            contentSections[sectionIndex].storeAnswer(answer: answer.copyAnwser())
                            //Force the parent view to refresh the test lines status
                            contentSection.questionStatus.setStatus(1)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("End of Exam").defaultButtonStyle()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                else {
                    ContentTypeView(contentSection: contentSections[sectionIndex],
                                    answerState: $answerState,
                                    answer: $answer
                                    //parentSelectionIndex: $sectionIndex
                    )
                }
            }
        }
        .navigationBarHidden(isNavigationHidden())
        .onAppear() {
            self.sectionIndex = 0
        }
    }
}

struct ContentOverviewView: View {
    let contentSection:ContentSection
    let googleAPI = GoogleAPI.shared
    @State var HTMLcontent: String?
    
    init(contentSection:ContentSection) {
        self.contentSection = contentSection
    }
    
    struct HTMLOverviewView: UIViewRepresentable {
        var htmlDocument:String

        func makeUIView(context: Context) -> WKWebView {
            return WKWebView()
        }
        
        func updateUIView(_ uiView: WKWebView, context: Context) {
            uiView.loadHTMLString(htmlDocument.trimmingCharacters(in: .whitespaces), baseURL: nil)
        }
    }
    
    func getContent()  {
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(UIGlobals.getAgeGrpup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: contentSection.type, reportError: false) {status,document in
            if status == .success {
                self.HTMLcontent = document ?? ""
            }
            else {
                self.HTMLcontent = "<!DOCTYPE html><html>Error:" + (document ?? "") + "</html>"
            }
        }
    }

    var body: some View {
        ZStack {
            Text("Overview").defaultTextStyle()
            if let content = self.HTMLcontent {
                HStack {
                    GeometryReader { geometry in
                        HTMLOverviewView(htmlDocument: content)
                            .frame(height: geometry.size.height * 0.8)
                            .overlay(
                                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                            )
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            getContent()
        }
        .onDisappear() {
            TTS.shared.stop()
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
    @Binding var parentSelectionIndex:Int?
    @State var isShowingConfiguration:Bool = false
    
    let id = UUID()
    
    init (contentSection:ContentSection, parentSelectionIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentSelectionIndex = parentSelectionIndex
    }
    
    init (contentSection:ContentSection) {
        self.contentSection = contentSection
        _parentSelectionIndex = .constant(nil)
    }

    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            let navigationView = SectionsNavigationView(contentSections: childSections)
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
                    ContentSectionHeaderView(contentSection: contentSection, parentSelection: navigationView)
                        //.border(Color.red)
                        .padding(.vertical, 0)
                    //SectionsNavigationView(contentSections: childSections)
                    navigationView
                        //.border(Color.blue)
                        .padding(.vertical, 0)
                }
            }
            else {
                if contentSection.type == "Overview" {
                    ContentOverviewView(contentSection: self.contentSection)
                }
                else {
                    ContentTypeView(contentSection: self.contentSection,
                                    answerState: $answerState,
                                    answer: $answer)
                }
            }
            if contentSection.subSections.count == 0 {
                if contentSection.type != "Overview" {
                    HStack {
                        ///Tell the parent to navigate to the next section
                        Button("Previous Example") {
                            if self.parentSelectionIndex == nil {
                                self.parentSelectionIndex = 0
                            }
                            else {
                                if self.parentSelectionIndex! > 0 {
                                    self.parentSelectionIndex! -= 1
                                }
                                else {
                                    self.parentSelectionIndex = nil
                                }
                            }
                        }
                        .padding()
                        Button("Next Example") {
                            if self.parentSelectionIndex == nil {
                                self.parentSelectionIndex = 0
                            }
                            else {
                                self.parentSelectionIndex! += 1
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        //.background(UIGlobals.colorNavigationBackground)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            if contentSection.answer111 != nil {
                //print("ContentSectionView ==== did set answer submitted", answerState)
                self.answerState = .submittedAnswer
                self.answer = contentSection.answer111!
            }
            else {
                //print("ContentSectionView ==== did NOT set answer submitted", answerState)
            }
            
        }
        .onDisappear() {
            TTS.shared.stop()
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingConfiguration = true
                }) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                }
            }
        }
        .sheet(isPresented: $isShowingConfiguration) {
            ConfigurationView(isPresented: $isShowingConfiguration,
                              colorScore: UIGlobals.colorScore,
                              colorBackground: UIGlobals.colorBackground,
                              colorInstructions: UIGlobals.colorInstructions,
                              ageGroup: UIGlobals.ageGroup)
        }
    }
}

