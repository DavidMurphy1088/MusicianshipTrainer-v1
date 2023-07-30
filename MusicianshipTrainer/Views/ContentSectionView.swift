import SwiftUI
import WebKit

///A protocol that any view that instances a test view must comply with so that the user can navigate directly to the next test
protocol NextNavigationView {
    //var property: String { get set }
    //func navigateNext()
    //func hasNextPage() -> Bool
    func enableNextNavigation() -> Bool
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
    
struct ContentSectionView: View, NextNavigationView {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var selectedContentIndex: Int?
    @State private var examSectionIndex: Int = 0
    @State private var showNextNavigation: Bool = true

    let id = UUID()
    var contentSection:ContentSection

    init(contentSection:ContentSection) {
        self.contentSection = contentSection
        examSectionIndex = 0
        //_parentsSelectedContentIndex1 = parentsSelectedContentIndex
    }
        
    func enableNextNavigation() -> Bool {
        if self.examSectionIndex < contentSection.getNavigableChildSections().count - 1 {
            DispatchQueue.main.async {
                ///Keep this 2nd check in this thread (or else wait for last call to complete). It appears this func can be called rapidly in succession
                if self.examSectionIndex < contentSection.getNavigableChildSections().count - 1 {
                    showNextNavigation = true
                    self.examSectionIndex += 1
                    print("_________________ enableNextNavigation::", self.examSectionIndex, "count:", contentSection.getNavigableChildSections().count)
                }
                else {
                    self.examSectionIndex = 0
                }
            }
        }
        return showNextNavigation
    }

    func getImageName(contentSection: ContentSection) -> String? {
        if contentSection.isExamMode()  {
            if contentSection.index < 6 {
                if contentSection.index == 2 || contentSection.index == 5 {
                    return "grade_b"
                }
                return "grade_a"
            }
        }
        return nil
    }
    
    func getStatus(contentSection: ContentSection) -> String {
        if contentSection.isExamMode()  {
            if contentSection.index < 6 {
                return "Completed"
            }
        }
        return ""
    }
    
    func log() -> Bool {
        print("===============>>>>>>>", examSectionIndex)
        return true
    }
    
    func examView(childSections:[ContentSection]) -> some View {
        ///Force an .onAppear for the next view to ensure it initializes with the new data from the next content section.
        ///This is required if two consecutive views are for the same content type (but different data) - on .onAppear must be forced ...
        VStack {
            Text("===examView=== Index::\(examSectionIndex) Sections::\(childSections.count)")
            if self.showNextNavigation {
                if examSectionIndex < childSections.count {
                    Text("Section \(childSections[examSectionIndex].name)").padding()
                    Text("Section \(examSectionIndex+1) of \(childSections.count) sections").padding()
                    Button(action: {
                        self.showNextNavigation = false
                    }) {
                        //Text("---- GO TO NEXT--- name:\(contentSection.name) index:\(examSectionIndex) childs:\(childSections.count)")
                        Text("Start Section \(childSections[examSectionIndex].name)").padding()
                    }
                }
                else {
                    Text("===examView INDEX ERROR === Index::\(examSectionIndex) Sections::\(childSections.count)")
                }
            }
            else {
                if log() {
                    questionTypeView(contentSection: childSections[examSectionIndex])
                }
            }
        }
        //.onAppear {
        //}
    }

    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            if childSections.count > 0 {

                ContentSectionHeaderView(contentSection: contentSection)

                if contentSection.type == "Exam" {
                    examView(childSections: childSections)
                }
                else {
                    sectionsView(childSections: childSections)
                }
            }
            else {
                questionTypeView(contentSection: self.contentSection)
            }
            
        }
        .onAppear {
            //self.childSections = contentSection.getNavigableChildSections()
        }

        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }
    
    func sectionsView(childSections:[ContentSection]) -> some View {
        VStack {

            List(Array(childSections.indices), id: \.self) { index in
                ///- selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`.
                NavigationLink(destination: ContentSectionView(contentSection: childSections[index]),
                                                               //parentsSelectedContentIndex: $selectedContentIndex),
                               tag: index,
                               selection: $selectedContentIndex) {

                    HStack {
                        Text(childSections[index].getTitle()).padding().font(.title2)
                        Spacer()
                        HStack {
                            Spacer()
                            Text(self.getStatus(contentSection: childSections[index])).padding().font(.title2)
                            if let imageName = getImageName(contentSection: childSections[index]) {
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
//            if showNextNavigation {
//            }
        }
    }
    
    func questionTypeView(contentSection:ContentSection) -> some View {
        VStack {
            let type = contentSection.type
           
            if type == "Type_1" {
                IntervalView(
                    questionType: QuestionType.intervalVisual,
                    contentSection: contentSection,
                    nextNavigationView: self
                )
            }
            if type == "Type_2" {
                VStack {
                    ClapOrPlayView (
                        questionType: QuestionType.rhythmVisualClap,
                        contentSection: contentSection,
                        nextNavigationView: self
                    )
                }
            }
            if type == "Type_3" {
                ClapOrPlayView (
                    questionType: QuestionType.melodyPlay,
                    contentSection: contentSection,
                    nextNavigationView: self
                )
            }
            if type == "Type_4" {
                IntervalView(
                    questionType: QuestionType.intervalAural,
                    contentSection: contentSection,
                    nextNavigationView: self
                )
            }
            if type == "Type_5" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmEchoClap,
                    contentSection: contentSection,
                    nextNavigationView: self
                )
            }
        }
        .onAppear {
            contentSection.setAnswerState(ctx: "ContentView", .notEverAnswered)
        }
    }
    
}


//    func navigateNext() {
//        guard let parent = contentSection.parent else {
//            return
//        }
//        let childSections = parent.getNavigableChildSections()
//
//        print("======nextContentSection \(contentSection.name)", "index:\(selectedContentIndex)", "SubsectionCount", childSections.count)
//        if parentsSelectedContentIndex == nil {
//            if childSections.count > 0 {
//                parentsSelectedContentIndex = 0
//            }
//        }
//        else {
//            if parentsSelectedContentIndex! < childSections.count {
//                parentsSelectedContentIndex! += 1
//            }
//            else {
//                parentsSelectedContentIndex = nil;
//            }
//        }
//    }
//    func hasNextPage() -> Bool {
//        if let parentSection = contentSection.parent {
//            if let parentsSelectedContentIndex = parentsSelectedContentIndex {
//                return parentsSelectedContentIndex < parentSection.getQuestionCount() - 1
//            }
//            return true
//        }
//        return false
//    }
        
