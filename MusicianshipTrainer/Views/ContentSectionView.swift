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
    let googleAPI = GoogleAPI()
    @State private var isHelpPresented = false
    @State private var instructions:String? = nil

    func getInstructions()  {
        let instructionContent = contentSection.getChildSectionByName(name: "Instructions")
        if let instructions = instructionContent?.instructions {
            googleAPI.getDocumentByName(name: instructions) {status,document in
                print(status, document)
                self.instructions = document
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
            }
                        
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
    
struct ContentSectionView: View {
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    
    init(contentSection:ContentSection) {
        self.contentSection = contentSection
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
                    List(contentSection.subSections) { subSection in
                        if !subSection.type.hasPrefix("I") {
                            NavigationLink(destination: ContentSectionView(contentSection: subSection)) {
                                VStack {
                                    Text(subSection.getTitle()).padding()
                                    //Text("___")
                                    //.navigationBarTitle("Title").font(.largeTitle)
                                    //.navigationBarTitleDisplayMode(.inline)
                                        .font(.title2)
                                }
                            }
                        }
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
                    ClapOrPlayView (
                        mode: QuestionMode.rhythmVisualClap,
                         //presentType: IntervalPresentView.self,
                         //answerType: IntervalAnswerView.self,
                         contentSection: contentSection
                     )

                }
                if path.contains("Playing") {
                    ClapOrPlayView (
                        mode: QuestionMode.melodyPlay,
                         //presentType: IntervalPresentView.self,
                         //answerType: IntervalAnswerView.self,
                         contentSection: contentSection
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
                         contentSection: contentSection
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


