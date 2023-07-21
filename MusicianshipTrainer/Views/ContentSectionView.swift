import SwiftUI
import WebKit

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
    
struct ContentSectionView: View {
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    @Binding var parentsSelectedContentIndex: Int?
    @State private var selectedContentIndex: Int?

    init(contentSection:ContentSection, parentsSelectedContentIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentsSelectedContentIndex = parentsSelectedContentIndex
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
    
    func nextContentSection() {
        print("======nextContentSection ", self.parentsSelectedContentIndex, "SubsectionCount", parentSection?.subSections.count)
        self.parentsSelectedContentIndex! += 1
    }
    
    var body: some View {
        VStack {
            if contentSection.subSections.count > 0 {

                ContentSectionHeaderView(contentSection: contentSection)
                
                VStack {

                    List(getContentIndexes(), id: \.self) { index in
                        NavigationLink(destination: ContentSectionView(contentSection: contentSection.subSections[index],
                                                                       parentsSelectedContentIndex: $selectedContentIndex),
                                       tag: index,
                                       selection: $selectedContentIndex) {
                            VStack {
                                Text(contentSection.subSections[index].getTitle()).padding()
                                    .font(.title2)
                            }

                        }
                    }
                }
                //.border(Color.green)
            }
            else {
                let path = contentSection.getPath()
                let type = ExampleData.shared.getType(key: contentSection.loadedDictionaryKey)
                if type == "Type.1" {
                   IntervalView(
                        mode: QuestionMode.intervalVisual,
                        contentSection: contentSection,
                        parent: self
                    )
                }
                if type == "Type.2" {
                    VStack {
                        ClapOrPlayView (
                            mode: QuestionMode.rhythmVisualClap,
                            contentSection: contentSection,
                            parent: self
                        )
                    }

                }
                if type == "Type.3" {
                    ClapOrPlayView (
                        mode: QuestionMode.melodyPlay,
                        contentSection: contentSection,
                        parent: self
                     )
                }
                if type == "Type.4" {
                   IntervalView(
                        mode: QuestionMode.intervalAural,
                        contentSection: contentSection,
                        parent: self
                    )
                }
                if type == "Type.5" {
                    ClapOrPlayView (
                        mode: QuestionMode.rhythmEchoClap,
                        contentSection: contentSection,
                        parent: self
                     )
                }
             }
        }
        .onAppear {
            //print("===========================================>", contentSection.name, contentSection.subSections.count, contentSection.loadedDictionaryKey)
        }


        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
    }

}


