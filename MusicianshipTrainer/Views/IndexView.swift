import SwiftUI
import CoreData

struct IndexView1: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isShowingConfiguration = false

    var body: some View {
        TabView {
            TestView()
                .tabItem {Label("TestView", systemImage: "music.quarternote.3")}
            
            //            SoundAnalyseView()
            //                .tabItem {Label("IndexView", systemImage: "music.quarternote.3")}
            //
            //
            //            ClapOrPlayView(
            //                mode: QuestionMode.rhythmVisualClap,
            //                contentSection: ContentSection(parent: nil,
            //                                               type: ContentSection.SectionType.testType,
            //                                               name: "test_clap")
            //            )
            //            .tabItem {Label("Clap_Test", systemImage: "music.quarternote.3")
            //            }
            
            IntervalView(
                mode: QuestionMode.intervalAural,
                contentSection: ContentSection(parent: nil,
                                               type: ContentSection.SectionType.testType,
                                               name: "test_aural_interval")
            )
            .tabItem {
                Label("IntervalView", systemImage: "music.quarternote.3")
            }
            
            ClapOrPlayView(
                mode: QuestionMode.melodyPlay,
                contentSection: ContentSection(parent: nil,
                                               type: ContentSection.SectionType.testType,
                                               name: "test_clap")
            )
            .tabItem {
                Label("ClapOrPlayView", systemImage: "music.quarternote.3")
            }
            
            
            TopicsNavigationView(topic: MusicianshipTrainerApp.root)
                .tabItem {
                    Label("MainApp", systemImage: "music.quarternote.3")
                }

        }
    }
}




