import SwiftUI
import WebKit

///A protocol that any view that instances a test view must comply with so that the user can navigate directly to the next test
protocol NextNavigationView {
    //var property: String { get set }
    func navigateNext()
    func hasNextPage() -> Bool
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

    let id = UUID()
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    @Binding var parentsSelectedContentIndex: Int?
    @State private var selectedContentIndex: Int?
    @State private var examSectionIndex: Int = 0

    init(contentSection:ContentSection, parentsSelectedContentIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentsSelectedContentIndex = parentsSelectedContentIndex
    }
    
    func navigateNext() {
        //print("======nextContentSection ", self.parentsSelectedContentIndex, "SubsectionCount", parentSection?.subSections.count)
        
        if parentsSelectedContentIndex != nil {
            //if parentsSelectedContentIndex
            DispatchQueue.main.async {
                //sleep(3)
                self.presentationMode.wrappedValue.dismiss()
            }
            //parentsSelectedContentIndex! += 1
        }
        print("Content view:: navigate next parentsSelectedContentIndex::id:", self.id.uuidString.prefix(8), parentsSelectedContentIndex)

    }
    
    func hasNextPage() -> Bool {
        if let parentSection = parentSection {
            if let parentsSelectedContentIndex = parentsSelectedContentIndex {
                return parentsSelectedContentIndex < parentSection.subSections.count - 1
            }
            return true
        }
        return false
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
    
    func examView(childSections:[ContentSection]) -> some View {
        VStack {
            Button(action: {
                self.examSectionIndex += 1
            }) {
                Text("__NEXT__")
            }
            questionTypeView(contentSection: childSections[examSectionIndex])
        }
    }

    var body: some View {
        VStack {
            let childSections = contentSection.getNavigableChildSections()
            if childSections.count > 0 {
                
                ContentSectionHeaderView(contentSection: contentSection)
                    .layoutPriority(1)
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
//        .onAppear {
//            let old = selectedContentIndex
//            if contentSection.type == "Exam" {
//                //very problematic - sometimes setting the selectedContentIndex does not work and the view just lists all its children
//                //rather than navigating to the first
//                if selectedContentIndex == nil {
////                    selectedContentIndex = 0
////                    DispatchQueue.main.async {
////                        //sleep(1)
////                        ussleep(500,000)
////                        selectedContentIndex = 0
////                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                        // this code will be executed after 0.5 seconds without blocking the current thread
//                        print("End")
//                        selectedContentIndex = 0
//                    }
//                }
//                print("========== Content sec view OnAppear \(contentSection.name) type:\(contentSection.type)", "old:\(String(describing: old))", "new:\(selectedContentIndex)", "id:", self.id.uuidString.prefix(8))
//
//            }
        //}
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }
    
    func sectionsView(childSections:[ContentSection]) -> some View {
        VStack {
//            Button(action: {
//                self.presentationMode.wrappedValue.dismiss()
//            }) {
//                Text("BACK")
//            }
//
            List(Array(childSections.indices), id: \.self) { index in
                ///- selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`.
                NavigationLink(destination: ContentSectionView(contentSection: childSections[index],
                                                               parentsSelectedContentIndex: $selectedContentIndex),
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
        }
    }
    
    func questionTypeView(contentSection:ContentSection) -> some View {
        VStack {
            let type = contentSection.type
            let testMode = TestMode(mode: contentSection.isExamMode() ? .exam : .practice)
            
            if type == "Type_1" {
                IntervalView(
                    questionType: QuestionType.intervalVisual,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
            if type == "Type_2" {
                VStack {
                    ClapOrPlayView (
                        questionType: QuestionType.rhythmVisualClap,
                        contentSection: contentSection,
                        testMode: testMode,
                        nextNavigationView: self,
                        answer: Answer()
                    )
                }
            }
            if type == "Type_3" {
                ClapOrPlayView (
                    questionType: QuestionType.melodyPlay,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
            if type == "Type_4" {
                IntervalView(
                    questionType: QuestionType.intervalAural,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
            if type == "Type_5" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmEchoClap,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
        }
    }
    
}


