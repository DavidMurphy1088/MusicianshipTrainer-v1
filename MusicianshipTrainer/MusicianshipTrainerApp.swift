import SwiftUI
import FirebaseCore
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        Logger.logger.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
        //Make navigation titles at top larger font
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.font : UIFont.systemFont(ofSize: 24, weight: .bold)]
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        
        return true
    }
    
    //Never appears to be called?
    //App somehow independently does UI to ask permission
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            if granted {
                Logger.logger.log(self, "Microphone usage granted")
            } else {
                Logger.logger.reportError(self, "Microphone Usage not granted")
            }
        }
    }
    
    static func startAVAudioSession(category: AVAudioSession.Category) {
        do {
            try AVAudioSession.sharedInstance().setCategory(category, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error {
            Logger.logger.reportError(self, "Set AVAudioSession category failed", error)
        }
    }
}

@main
struct MusicianshipTrainerApp: App {
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject var logger = Logger.logger
    static let productionMode = true
    @ObservedObject var exampleData = ExampleData.shared1
    //product licensed by grade 14Jun23
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Grade 1")
    static let root:ContentSection = ContentSection(parent: nil, name: "", type: "")
    let settings:Settings = Settings.shared
    var launchTimeSecs = 4.5

    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

    }
    
    func getStartContentSection() -> ContentSection {
        var cs:ContentSection
        //if MusicianshipTrainerApp.productionMode {
            cs = MusicianshipTrainerApp.root//.subSections[1].subSections[0] //NZMEB, Grade 1
        //}
        //else {
            //cs = MusicianshipTrainerApp.root.subSections[1].subSections[0].subSections[0] //NZMEB, Grade 1, practice
        //}
        return cs
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished {
                    if exampleData.dataStatus == RequestStatus.success {
                        if !MusicianshipTrainerApp.productionMode {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                TestView().padding(.horizontal)
                            }
                        }

                        ContentNavigationView(contentSection: getStartContentSection())
                        ///No colour here appears to make a difference. i.e. be visible
                            //.background(Color(red: 0.0, green: 0.7, blue: 0.7))
                            .tabItem {Label("Exercises", image: "music.note")}
                    }
                    else {
                        if exampleData.dataStatus == RequestStatus.waiting {
                            Spacer()
                            Image(systemName: "hourglass.tophalf.fill")
                                .resizable()
                                .frame(width: 30, height: 60)
                                .foregroundColor(Color.blue)
                                .padding()
                            Text("")
                            Text("Loading Content...").font(.headline)
                            Spacer()
                        }
                        else {
                            VStack {
                                Text("Sorry, we could not create an internet conection.").font(.headline).foregroundColor(.red).padding()
                                Text("Please try again.").font(.headline).foregroundColor(.red).padding()
                                Text(" ").padding()
                                if let errMsg = logger.errorMsg {
                                    Text("Error:\(errMsg)").padding()
                                }
                            }
                        }
                    }
                }
                if MusicianshipTrainerApp.productionMode  {
                    if launchScreenState.state != .finished {
                        LaunchScreenView(launchTimeSecs: launchTimeSecs)
                    }
                }
            }
            .environmentObject(launchScreenState)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                    self.launchScreenState.dismiss()
                }
            }
        }
    }
}

