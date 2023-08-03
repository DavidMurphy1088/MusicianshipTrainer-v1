import SwiftUI
import CoreData

struct GradeIntroView: View {
    
    var body: some View {
            VStack  (alignment: .center) {
                //Text("TopicsNavigationView")
                Text("Musicianship Trainer")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Grade 1 Piano")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                //GeometryReader { geo in
                    Image("nzmeb_logo_transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200) //, height: 200)
                        .padding()
                //}
            }
    }
}

struct ContentNavigationView: View {
    let contentSection:ContentSection
    @State private var isShowingConfiguration = false
    @State private var selectedContentIndex: Int? = 0 //has to be optional for the case nothing is selected

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationView {
                VStack {
                    //This is the list placed in the split navigation screen.
                    //The 2nd NavigationView below (for iPhone without split nav) will present the topics on the first screen the user sees
//                    if false {
//                        List(contentSection.subSections) { contentSection in
//                            NavigationLink(destination: ContentSectionView(contentSection: contentSection)) {
//                                                                           //parentsSelectedContentIndex: $selectedContentIndex)) {
//                                Text(contentSection.getTitle())
//                                    .font(.title2)
//                            }
//                            .disabled(!contentSection.isActive)
//                        }
//                    }
                    
                    GradeIntroView()
                    
                    List(contentSection.subSections) { contentSection in
                        NavigationLink(destination: ContentSectionView(contentSection: contentSection)) {
                                                                       //parentsSelectedContentIndex: $selectedContentIndex)) {
                            VStack(alignment: .center) {
                                Text(contentSection.getTitle()).padding()
                                    .font(.title2)
                            }
                            //.navigationBarTitleDisplayMode(.inline)
                        }
                        .disabled(!contentSection.isActive)
                        //The back nav link that will be shown on the ContentSectionView
                        //.navigationTitle("NavTtitle::\(self.topic.level == 0 ? "" : topic.title)")
                   }
                    .sheet(isPresented: $isShowingConfiguration) {
                        ConfigurationView(isPresented: $isShowingConfiguration,
                                          colorScore: UIGlobals.colorScore,
                                          colorBackground: UIGlobals.colorBackground,
                                          colorInstructions: UIGlobals.colorInstructions)
                    }
                }
                //.navigationTitle(topic.name) ?? ignored??
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingConfiguration = true
                        }) {
                            Image(systemName: "gear")
                            .font(.largeTitle)
                            .scaleEffect(1.0)
                        }
                    }
                }
            }
            //On iPad, the default behavior of NavigationView is to display as a master-detail view in a split view layout. This means that the navigation view will be visible only when the app is running in a split-screen mode, such as in Split View or Slide Over.
            //When running the app in full-screen mode on an iPad, the NavigationView will collapse to a single view, and the navigation links will be hidden. This behavior is by design to provide a consistent user experience across different device sizes and orientations.
            .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle - turns off the split navigation on iPad
        }
        else {
            NavigationView {
                List(contentSection.subSections) { contentSection in
                    NavigationLink(destination: ContentSectionView(contentSection: contentSection)) {//}, parentsSelectedContentIndex: $selectedContentIndex)) {
                        VStack {
                            Text(contentSection.getTitle())
                                .font(.title2)
                                .padding()
                        }
                    }
                    .disabled(!contentSection.isActive)
                }
                .sheet(isPresented: $isShowingConfiguration) {
                    ConfigurationView(isPresented: $isShowingConfiguration,
                                      colorScore: UIGlobals.colorScore,
                                      colorBackground: UIGlobals.colorBackground,
                                      colorInstructions: UIGlobals.colorInstructions
                                    )
                }
                //.navigationTitle(topic.name)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button(action: {
//                            isShowingConfiguration = true
//                        }) {
//                            Image(systemName: "xgear")
//                                //.resizable()
//                                //.frame(width: 200, height: 200)
//                                //.font(.largeTitle)
//                                //.scaleEffect(1.5)
//                                .resizable()
//                                .frame(width: 132, height: 132)
//                        }
//                    }
//                }
            }
        }
    }
}
