import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit

///The view that runs a specifc example or test
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
    }
}

struct ContentSectionWebViewUI: UIViewRepresentable {
    var htmlDocument:String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlDocument, baseURL: nil)
    }
}

struct ContentSectionWebView: View {
    let htmlDocument:String
    let contentSection: ContentSection
    var body: some View {
        VStack {
            ZStack {
                ContentSectionWebViewUI(htmlDocument: htmlDocument).border(Color.black, width: 1).padding()
                NarrationView(contentSection: contentSection, htmlDocument: htmlDocument, context: "ContentSectionTipsView")
            }
        }
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
    var contentSectionView:ContentSectionView

    let googleAPI = GoogleAPI.shared
    @State private var isVideoPresented = false
    @State private var instructions:String? = nil
    @State private var tipsAndTricksExists = false
    @State private var tipsAndTricksData:String?=nil
    @State private var parentsExists = false
    @State private var parentsData:String?=nil
    @State private var audioInstructionsFileName:String? = nil
    
    func getInstructions(bypassCache:Bool)  {
        var pathSegments = contentSection.getPathAsArray()
        if pathSegments.count < 1 {
            return
        }
        let filename = "Instructions" //instructionContent.contentSectionData.data[0]
        pathSegments.append(UIGlobals.getAgeGroup())
        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.instructions = document
            }
        }
    }
    
    func getTipsTricksData(bypassCache: Bool)  {
        let filename = "Tips_Tricks"
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(UIGlobals.getAgeGroup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.tipsAndTricksExists = true
                self.tipsAndTricksData = document
            }
        }
    }
    
    func getParentsData(bypassCache: Bool)  {
        let filename = "Parents"
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(UIGlobals.getAgeGroup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.parentsExists = true
                self.parentsData = document
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
        //print(contentSection.getPathTitle(), "index", index)
        return true
    }
    
    var body: some View {
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
            
            HStack {
                if tipsAndTricksExists {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: tipsAndTricksData!, contentSection: contentSection)) {
                        VStack {
                            Text("Tips and Tricks")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .font(.largeTitle)
                        }
                    }
                    Spacer()
                    Button(action: {
                        isVideoPresented.toggle()
                    }) {
                        VStack {
                            VStack {
                                Text("Video")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                                Image(systemName: "video")
                                    .foregroundColor(.blue)
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .sheet(isPresented: $isVideoPresented) {
                        let urlStr = "https://storage.googleapis.com/musicianship_trainer/NZMEB/" +
                        contentSection.getPath() + "." + UIGlobals.getAgeGroup() + ".video.mp4"
                        //https://storage.googleapis.com/musicianship_trainer/NZMEB/Grade%201.PracticeMode.Sight%20Reading.11Plus.video.mp4
                        //Grade 1.PracticeMode.Sight Reading.11Plus.video.mp4
                        let allowedCharacterSet = CharacterSet.urlQueryAllowed
                        if let encodedString = urlStr.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                            if let url = URL(string: encodedString) {
                                GeometryReader { geo in
                                    VStack {
                                        VideoPlayer(player: AVPlayer(url: url))
                                    }
                                    .frame(height: geo.size.height)
                                }
                            }
                        }
                    }
                }
                
                if contentSection.getPathAsArray().count > 1 {
                    Spacer()
                    Button(action: {
                        DispatchQueue.main.async {
                            contentSectionView.randomPick()
                        }
                    }) {
                        VStack {
                            VStack {
                                Text("Random Pick")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                                Image(systemName: "tornado")
                                    .foregroundColor(.blue)
                                    .font(.title)
                            }
                        }
                    }
                }
                
                if parentsExists {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: parentsData!, contentSection: contentSection)) {
                        VStack {
                            Text("Parents")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                }
                Spacer()
            }
            
            Button(action: {
                DispatchQueue.main.async {
                    self.getInstructions(bypassCache: true)
                    self.getTipsTricksData(bypassCache: true)
                    self.getParentsData(bypassCache: true)
                }
            }) {
                VStack {
                        Text("ReloadHTML")
                            .font(.title3)
                            .padding(0)
                }
                .padding(0)
            }
            
        }
        .onAppear() {
            getAudio()
            getInstructions(bypassCache: false)
            getTipsTricksData(bypassCache: false)
            getParentsData(bypassCache: false)
        }
    }
}

class NavigationStateManager: ObservableObject {
    @Published var selectedIndex: Int?
}

struct SectionsNavigationView:View {
    let contentSections:[ContentSection]
    let contentSectionView:ContentSectionView
    @Binding var makeRandomChoice:Bool
    @StateObject private var navigationManager = NavigationStateManager()
    
//    init(contentSections:[ContentSection], contentSectionView:ContentSectionView) {
//        self.contentSections = contentSections
//        self.contentSectionView = contentSectionView
//
//    }
//
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
    
    func randomSelection(withDelay:Bool) {
        let range = contentSections.count
        let random = Int.random(in: 0...range-1)
        let delta = 0.40
        DispatchQueue.main.async {
            navigationManager.selectedIndex = random
            if withDelay {
                ///Let the parent view's scroller scroll to the correct row but then force a change of selected index to make the new child view appear
                DispatchQueue.main.async {//After(deadline: .now() + delta) {
                    navigationManager.selectedIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2 * delta) {
                        navigationManager.selectedIndex = random
                    }
                }
            }
        }
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
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                List(Array(contentSections.indices), id: \.self) { index in
                    ///selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`
                    ///tag: The value of `selection` that causes the link to present `destination`..
                    NavigationLink(destination:
                                    ContentSectionView(contentSection: contentSections[index], contentSectionView: self,
                                                       //parentSelectionIndex: $selectedIndex
                                                       parentSelectionIndex: $navigationManager.selectedIndex)
                                   ,
                                   tag: index,
                                   //selection: $selectedIndex
                                   selection: $navigationManager.selectedIndex
                    ) {
                        
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
                }
                ///This color matches the NavigationView background which cannot be changed.
                ///i.e. any other colour here causes the navigation link rows to have a different background than the background of the navigationView's own background
                ///If the random row does not require the ScrollViewReader to scroll then the view for that random row is made visible
                ///If the random row does require the ScrollViewReader to scroll then it scrolls, goes into the new child view briefly but then exits back to the parent view
                .listRowBackground(Color(.secondarySystemBackground))
                .onChange(of: navigationManager.selectedIndex) { newIndex in
                    if let newIndex = newIndex {
                        proxy.scrollTo(newIndex)
                    }
                }
                .onChange(of: makeRandomChoice) { newState in
                    makeRandomChoice = false
                    self.randomSelection(withDelay: false)
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
    @State private var showingConfirm = false
    @State private var examInstructionsStatus:String = "Waiting for instructions"

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
                Spacer()
                Button(action: {
                    self.examBeginning = false
                    AudioRecorder.shared.stopPlaying()
                }) {
                    VStack {
                        Text(examInstructionsStatus).padding()
                        //Text("The exam has \(contentSections.count) questions").defaultTextStyle().padding()
                        Text("Start the Exam").defaultButtonStyle()
                    }
                }
                Spacer()
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
                                    let answer = Answer(ctx: "cancelled")
                                    s.answer111 = answer
                                    s.storeAnswer(answer: answer)
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
            contentSection.playExamInstructions(onStarted: instructionsStarted)
        }
    }
    
    func instructionsStarted(status:RequestStatus) {
        if status == .success {
            examInstructionsStatus = ""
        }
        else {
            examInstructionsStatus = "Cannot read instructions"
        }
    }
}

struct ContentSectionView: View {
    let contentSection:ContentSection
    let contentSectionView: (any View)
    @State private var showNextNavigation: Bool = true
    @State private var endOfSection: Bool = false
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer(ctx: "ContentSectionView")//, questionMode: .practice)
    @Binding var parentSelectionIndex:Int?
    @State var isShowingConfiguration:Bool = false
    @StateObject private var navigationManager = NavigationStateManager()
    @State var random:Bool = false

    let id = UUID()
    
    init (contentSection:ContentSection, contentSectionView:(any View), parentSelectionIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentSelectionIndex = parentSelectionIndex
        self.contentSectionView = contentSectionView
    }
    
    init (contentSection:ContentSection, contentSectionView:(any View)) {
        self.contentSection = contentSection
        _parentSelectionIndex = .constant(nil)
        self.contentSectionView = contentSectionView
    }
    
    func randomPick() {
        let range = contentSection.subSections.count
        self.random = true
    }
    
//    func log(v:(any View)) -> Bool {
//        print("=====>>", v)
//        return true
//    }
    
    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            if childSections.count > 0 {
                if contentSection.isExamTypeContentSection() {
                    //No ContentSectionHeaderView in any exam mode content section except the exam start
                    if contentSection.hasExamModeChildren() {
                        ContentSectionHeaderView(contentSection: contentSection, contentSectionView: self)
                            //.border(Color.red)
                            .padding(.vertical, 0)

                        SectionsNavigationView(contentSections: childSections, contentSectionView: self, makeRandomChoice: $random)
                    }
                    else {
                        if contentSection.hasNoAnswers() {
                            GeometryReader { geo in
                                ExamView(contentSection: contentSection, contentSections: childSections)
                                    .frame(width: geo.size.width)
                                    //.border(Color.red)
                            }
                        }
                        else {
                            //Exam was taken
                            SectionsNavigationView(contentSections: childSections, contentSectionView: self, makeRandomChoice: $random)
                        }
                    }
                }
                else {
                    ScrollViewReader { proxy in
                        ContentSectionHeaderView(contentSection: contentSection, contentSectionView: self)
                            //.border(Color.red)
                            .padding(.vertical, 0)
                    
                        SectionsNavigationView(contentSections: childSections, contentSectionView: self, makeRandomChoice: $random)
                        //.border(Color.blue)
                            .padding(.vertical, 0)
                            .onChange(of: navigationManager.selectedIndex) { newValue in
                                if let newValue = newValue {
                                    proxy.scrollTo(newValue, anchor: .top)
                                }
                            }
                    }
                }
            }
            else {
                ContentTypeView(contentSection: self.contentSection,
                                answerState: $answerState,
                                answer: $answer)
            }
            if contentSection.subSections.count == 0 {
                HStack {
                    ///Tell the parent to navigate to the next section
                    if let navigationView = self.contentSectionView as? SectionsNavigationView {
                        Button("Random Example") {
                            navigationView.randomSelection(withDelay: true)
                        }
                        .padding()
                    }
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
        //.background(UIGlobals.colorNavigationBackground)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            if contentSection.answer111 != nil {
                self.answerState = .submittedAnswer
                self.answer = contentSection.answer111!
            }
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingConfiguration = true
                }) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.blue)
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .largeTitle)
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

