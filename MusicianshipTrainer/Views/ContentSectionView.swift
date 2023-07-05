import SwiftUI
import WebKit

struct ContentSectionHelpView: UIViewRepresentable {
    var contentSection:ContentSection

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        //print(contentSection.name)
        if let htmlPath = Bundle.main.path(forResource: contentSection.name, ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}
   
struct ContentSectionHeaderView: View {
    var contentSection:ContentSection
    @State private var isHelpPresented = false
    var help:String = "In the exam you will be shown three notes and be asked to identify the intervals as either a second or a third."
    
    var body: some View {
        VStack {
            //Text("ContentSectionView Level:\(contentSection.level) name:\(contentSection.name) name:\(contentSection.title)").font(.title)
            Text("\(contentSection.title)").font(.title)
                .fontWeight(.bold)
                .padding()
            if contentSection.level == 1 {
                HStack {
                    Text(contentSection.instructions)
                        //.font(.body)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .padding()
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
            }
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
            if parentType!.sectionType == ContentSection.SectionType.testType {
                self.parentSection = parentType!
                break
            }
            parentType = parentType!.parent
        }
        //print("ContentSectionView", contentSection.name, contentSection.subSections.count, "parentType", parentType?.name)
    }
   
    var body: some View {
        VStack {
            
            if contentSection.subSections.count > 0 {
                ContentSectionHeaderView(contentSection: contentSection)
                    .padding()
                VStack {
                    List(contentSection.subSections) { subtopic in
                        NavigationLink(destination: ContentSectionView(contentSection: subtopic)) {
                            VStack {
                                Text(subtopic.title).padding()
                                //Text("___")
                                //.navigationBarTitle("Title").font(.largeTitle)
                                //.navigationBarTitleDisplayMode(.inline)
                                    .font(.title2)
                            }
                        }
                    }
                }
            }
            else {
                if let parentSection = parentSection {
                    if parentSection.sectionType == ContentSection.SectionType.testType {
                        if parentSection.name.contains("Intervals Visual") {
                           IntervalView(
                                mode: QuestionMode.intervalVisual,
                                contentSection: contentSection
                            )
                        }
                        if parentSection.name.contains("Clapping") {
                            ClapOrPlayView (
                                mode: QuestionMode.rhythmVisualClap,
                                 //presentType: IntervalPresentView.self,
                                 //answerType: IntervalAnswerView.self,
                                 contentSection: contentSection
                             )

                        }
                        if parentSection.name.contains("Playing") {
                            ClapOrPlayView (
                                mode: QuestionMode.melodyPlay,
                                 //presentType: IntervalPresentView.self,
                                 //answerType: IntervalAnswerView.self,
                                 contentSection: contentSection
                             )
                        }
                        if parentSection.name.contains("Intervals Aural") {
                           IntervalView(
                                mode: QuestionMode.intervalAural,
                                contentSection: contentSection
                            )
                        }
                        if parentSection.name.contains("Echo Clap") {
                            ClapOrPlayView (
                                mode: QuestionMode.rhythmEchoClap,
                                 contentSection: contentSection
                             )
                        }
                    }
                }
             }
        }
        .navigationBarTitle(contentSection.level > 1 ? contentSection.getPathTitle() : "", displayMode: .inline)//.font(.title)
        //.navigationBarTitle(contentSection.level > 1 ? contentSection.getPathName() : "", displayMode: .inline)//.font(.title)
    }
}


