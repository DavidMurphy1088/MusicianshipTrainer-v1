import SwiftUI
import WebKit

struct ContentSectionTipsView: UIViewRepresentable {
    var contentSection:ContentSection
    let exampleData = ExampleData.shared
    let googleAPI = GoogleAPI.shared

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let key = contentSection.getPath() + "." + "TipsAndTricks"
        let array = exampleData.getData(key: key, type: "I")
        if let array = array {
            let file:String = array[0] as! String
            print(file)
            googleAPI.getDocumentByName(name: file) {status,document in
                if status == .success {
                    if let document = document {
                        let htmlDocument:String = document
                        uiView.loadHTMLString(htmlDocument, baseURL: nil)
                    }
                }
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
    let googleAPI = GoogleAPI.shared
    @State private var isHelpPresented = false
    @State private var instructions:String? = nil
    @State private var tipsAndTricksExists = false

    func getInstructions()  {
        let instructionContent = contentSection.getChildSectionByName(name: "Instructions")
        if let instructions = instructionContent?.instructions {
            googleAPI.getDocumentByName(name: instructions) {status,document in
                //print(status, document)
                if status == .success {
                    self.instructions = document
                }
            }
        }
    }
    
    func getTipsAndTricks()  {
        let tipsAndTricksContent = contentSection.getChildSectionByName(name: "TipsAndTricks")
        if let tipsAndTricks = tipsAndTricksContent?.instructions {
            googleAPI.getDocumentByName(name: tipsAndTricks) {status,document in
                //print(status, document)
                if status == .success {
                    self.tipsAndTricksExists = true
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
                    ContentSectionTipsView(contentSection: contentSection)
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
    
struct ContentSectionView: View {
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    @Binding var parentsSelectedContentIndex: Int?
    @State private var selectedContentIndex: Int?

    init(contentSection:ContentSection, parentsSelectedContentIndex:Binding<Int?>) {
        self.contentSection = contentSection
        _parentsSelectedContentIndex = parentsSelectedContentIndex
        print("------ContentSectionView init", contentSection.level, contentSection.name, parentsSelectedContentIndex)
    }
   
    func getContentIndexes() -> [Int] {
        var indexes:[Int] = []
        var i = 0
        for section in contentSection.subSections {
            if !section.type.hasPrefix("I") {
                indexes.append(i)
            }
            i += 1
        }
        return [0,1,2,3]
    }
    
    func nextContentSection() {
        self.parentsSelectedContentIndex! += 1
        //print("===>Next Inc", self.selectedContentIndex ?? "nil")
    }
    
    var body: some View {
        VStack {
            if contentSection.subSections.count > 0 {
                //Spacer()
                //GeometryReader { geometry in
                ContentSectionHeaderView(contentSection: contentSection)
                //.frame(height: 200)
                //.frame(height: geometry.size.height / 3)
                //NOTE: using geometry appears to ruin the rest of the layout - e..g huge vertical space between insructions and List
                
                //.padding(.vertical None)
                //.border(Color.red)
                //}
                VStack {
//                    List(contentSection.subSections) { subSection in
//                        if !subSection.type.hasPrefix("I") {
//                            NavigationLink(destination: ContentSectionView(contentSection: subSection)
//                                           //tag: subSection.id, selection: selectedContentIndex
//                            ) {
//                                VStack {
//                                    Text(subSection.getTitle()).padding()
//                                    //Text("___")
//                                    //.navigationBarTitle("Title").font(.largeTitle)
//                                    //.navigationBarTitleDisplayMode(.inline)
//                                        .font(.title2)
//                                }
//                            }
//                        }
//                    }
                    List(getContentIndexes().indices, id: \.self) { index in
                        NavigationLink(destination: ContentSectionView(contentSection: contentSection.subSections[index],
                                                                       parentsSelectedContentIndex: $selectedContentIndex),
                                       tag: index,
                                       selection: $selectedContentIndex) {
                            VStack {
                                Text(contentSection.subSections[index].getTitle())//.padding()
                                Text("selected:\(self.selectedContentIndex ?? -1) listIndex:\(index)")
                                //Text("___")
                                //.navigationBarTitle("Title").font(.largeTitle)
                                //.navigationBarTitleDisplayMode(.inline)
                                    .font(.title2)
                            }

                        }
                    }
                    .onAppear {
//                        print("============OnApper \(self.selectedContentIndex ?? -1)" )
//                        if self.selectedContentIndex == nil {
//                            self.selectedContentIndex = 0
//                        }
                    }

                }
                //.border(Color.green)
                //Spacer()
            }
            else {
                let path = contentSection.getPath()
                if path.contains("Intervals Visual") {
                   IntervalView(
                        mode: QuestionMode.intervalVisual,
                        contentSection: contentSection
                    )
                }
                if path.contains("Clapping") {
                    VStack {
                        ClapOrPlayView (
                            mode: QuestionMode.rhythmVisualClap,
                            contentSection: contentSection,
                            parent: self
                        )
                    }

                }
                if path.contains("Playing") {
                    ClapOrPlayView (
                        mode: QuestionMode.melodyPlay,
                        contentSection: contentSection,
                        parent: self
                     )
                }
                if path.contains("Intervals Aural") {
                   IntervalView(
                        mode: QuestionMode.intervalAural,
                        contentSection: contentSection
                    )
                }
                if path.contains("Echo Clap") {
                    ClapOrPlayView (
                        mode: QuestionMode.rhythmEchoClap,
                        contentSection: contentSection,
                        parent: self
                     )
                }
             }
        }
        .navigationBarTitle(getNavTitle(), displayMode: .inline)//.font(.title)
    }
    
    func getNavTitle() -> String {
        //if contentSection.level > 1 {
            //if let parent = contentSection.parent {
                return contentSection.getTitle()
            //}
        //}
        //return ""
    }
}


