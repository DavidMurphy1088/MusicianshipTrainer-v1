import SwiftUI
import WebKit

struct ContentSectionHelpView: UIViewRepresentable {
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
   
struct ContentSectionHeaderView: View {
    var contentSection:ContentSection
    @State private var isHelpPresented = false
    var help:String = "In the exam you will be shown three notes and be asked to identify the intervals as either a second or a third."
    
    var body: some View {
        VStack {
            Text("\(contentSection.getTitle())").font(.title)
                .fontWeight(.bold)
                .padding()
            //if contentSection.level == 1 {
                HStack {
//                    Text(contentSection.instructions ?? "loading...")
//                        //.font(.body)
//                        .font(.title2)
//                        .multilineTextAlignment(.leading)
//                        .lineLimit(nil)
//                        .padding()
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
                    ContentSectionHelpView(contentSection: contentSection)
                        .padding()
                        .background(
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 4) 
                        )
                }
                .padding()
            //}
        }
    }
}
    
struct ContentSectionView: View {
    var contentSection:ContentSection
    var parentSection:ContentSection? // the parent of this section that describes the test type
    
    init(contentSection:ContentSection) {
        self.contentSection = contentSection
        var parentType:ContentSection? = contentSection

        while parentType != nil {
//            if parentType!.sectionType == ContentSection.SectionType.testType {
//                self.parentSection = parentType!
//                break
//            }
            parentType = parentType!.parent
        }
    }
   
    var body: some View {
        VStack {
            if contentSection.subSections.count > 0 {
                ContentSectionHeaderView(contentSection: contentSection)
                    .padding()
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
        .navigationBarTitle(contentSection.level > 1 ? contentSection.getPathTitle() : "", displayMode: .inline)//.font(.title)
        //.navigationBarTitle(contentSection.level > 1 ? contentSection.getPathName() : "", displayMode: .inline)//.font(.title)
    }
}


