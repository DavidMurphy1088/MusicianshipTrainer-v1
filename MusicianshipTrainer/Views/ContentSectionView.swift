import SwiftUI
import WebKit

///A protocol that any view that instances a test view must comply with so that the user can navigate directly to the next test
protocol NextNavigationView {
    //var property: String { get set }
    func navigateNext()
}

struct ContentSectionTipsView: UIViewRepresentable {
    //var contentSection:ContentSection
    //let exampleData = ExampleData.shared
    //let googleAPI = GoogleAPI.shared
    var htmlDocument:String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        let key = contentSection.getPath() + "." + "TipsAndTricks".
//        let array = exampleData.getData(key: key, type: "I")
//        if let array = array {
//            let file:String = array[0] as! String
//            googleAPI.getDocumentByName(name: file) {status,document in
//                if status == .success {
//                    if let document = document {
//                        let htmlDocument:String = document
//                        uiView.loadHTMLString(htmlDocument, baseURL: nil)
//                    }
//                }
//            }
//        }
//    }
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

    func getInstructions()  {
        let instructionContent = contentSection.getChildSectionByType(type: "Ins")
        if let instructionContent = instructionContent {
            let filename = ExampleData.shared.getFirstCol(key: instructionContent.loadedDictionaryKey)
            if let filename = filename {
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
            let filename = ExampleData.shared.getFirstCol(key: tipsAndTricksContent.loadedDictionaryKey)
            if let filename = filename {
                googleAPI.getDocumentByName(name: filename) {status,document in
                    if status == .success {
                        self.tipsAndTricksExists = true
                        self.tipsAndTricksData = document
                    }
                }
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
            .onAppear() {
                getInstructions()
                getTipsAndTricks()
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
    }
}
    
struct ContentSectionView: View, NextNavigationView {
    
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    @Binding var parentsSelectedContentIndex: Int?
    @State private var selectedContentIndex: Int?
    
    init(contentSection:ContentSection, parentsSelectedContentIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentsSelectedContentIndex = parentsSelectedContentIndex
    }
    
    func navigateNext() {
        //print("======nextContentSection ", self.parentsSelectedContentIndex, "SubsectionCount", parentSection?.subSections.count)
        if parentsSelectedContentIndex != nil {
            parentsSelectedContentIndex! += 1
        }
    }

    func getContentIndexes() -> [Int] {
        var indexes:[Int] = []
        var i = 0
        for section in contentSection.subSections {
            if section.type.isEmpty {
                indexes.append(i)
            }
            else {
                if section.type.hasPrefix("Type.") {
                    indexes.append(i)
                }
            }
            i += 1
        }
        return indexes
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
    
    func questionTypeView() -> some View {
        VStack {
            let path = contentSection.getPath()
            let type = ExampleData.shared.getType(key: contentSection.loadedDictionaryKey)
            let testMode = TestMode(mode: contentSection.isExamMode() ? .exam : .practice)
            
            if type == "Type.1" {
                IntervalView(
                    questionType: QuestionType.intervalVisual,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
            if type == "Type.2" {
                VStack {
                    ClapOrPlayView (
                        questionType: QuestionType.rhythmVisualClap,
                        contentSection: contentSection,
                        testMode: testMode,
                        nextNavigationView: self
                        //answer: Answer()
                    )
                }
                
            }
            if type == "Type.3" {
                ClapOrPlayView (
                    questionType: QuestionType.melodyPlay,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self
                    //answer: Answer()
                )
            }
            if type == "Type.4" {
                IntervalView(
                    questionType: QuestionType.intervalAural,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self,
                    answer: Answer()
                )
            }
            if type == "Type.5" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmEchoClap,
                    contentSection: contentSection,
                    testMode: testMode,
                    nextNavigationView: self
                    //answer: Answer()
                )
            }
        }
    }
    
    var body: some View {
        VStack {
            if contentSection.type == "Type.7" {
                ExamView(contentSection: contentSection)
            }
            else {
                if contentSection.subSections.count > 0 {
                    ContentSectionHeaderView(contentSection: contentSection)
                    VStack {
                        List(getContentIndexes(), id: \.self) { index in
                            NavigationLink(destination: ContentSectionView(contentSection: contentSection.subSections[index],
                                                                           parentsSelectedContentIndex: $selectedContentIndex),
                                           tag: index,
                                           selection: $selectedContentIndex) {
                                HStack {
                                    Text(contentSection.subSections[index].getTitle()).padding()
                                        .font(.title2)
                                    if let imageName = getImageName(contentSection: contentSection.subSections[index]) {
                                        Spacer()
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40.0)
                                        Text("          ")
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    questionTypeView()
                }
            }
        }
        .onAppear {
            //print("===========================================>", contentSection.name, contentSection.subSections.count, contentSection.loadedDictionaryKey)
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }

}


