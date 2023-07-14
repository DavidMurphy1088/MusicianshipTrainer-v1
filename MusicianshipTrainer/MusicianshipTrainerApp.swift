import SwiftUI
import FirebaseCore
import AVFoundation
//import GoogleSignIn
//import GoogleAPIClientForREST

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //FirebaseApp.configure()
        //Logger.logger.log(self, "Firebase Configured" )
        //print(FirebaseApp.defaultOptions)
        //FirebaseConfiguration.shared.setLoggerLevel(<#FirebaseLoggerLevel#>)
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        Logger.logger.log(self, "Version.Build \(appVersion).\(buildNumber)")
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
            //Logger.logger.log(self, "Set AVAudioSession category done, category \(category)")
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
    @ObservedObject var exampleData = ExampleData.shared
    @ObservedObject var logger = Logger.logger
    static let productionMode = false
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Musicianship")
    //product licensed by grade 14Jun23
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Grade 1")
    static let root:ContentSection = ContentSection(parent: nil, name: "", type: "")
    //var launchTimeSecs = 2.5
    var launchTimeSecs = 2.5

    init() {
    }
    
    func getStartContentSection() -> ContentSection {
        var cs:ContentSection
        if MusicianshipTrainerApp.productionMode {
            cs = MusicianshipTrainerApp.root.subSections[1].subSections[0] //NZMEB, Grade 1
        }
        else {
            cs = MusicianshipTrainerApp.root.subSections[1].subSections[0].subSections[0] //NZMEB, Grade 1, practice
        }
        return cs
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished {
                    if exampleData.dataStatus == RequestStatus.success {
                        if !MusicianshipTrainerApp.productionMode {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                TestView()
                            }
                        }

                        TopicsNavigationView(contentSection: getStartContentSection())
                            .tabItem {Label("Exercises", image: "music.note")}
                    }
                    else {
                        if exampleData.dataStatus == RequestStatus.waiting {
                            Spacer()
                            Image(systemName: "hourglass.tophalf.fill")
                                .resizable()
                                .frame(width: 30, height: 60)
                            //.scaleEffect(2.0)
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
//                                Button(action: {
//                                    logger.refresh()
//                                }) {
//                                    Text("Show Error")
//                                }
                                if let errMsg = logger.errorMsg {
                                    Text("Error:\(errMsg)").padding()
                                }
//                                if let
//                                Text("\(logger.loggedMsg)").padding()
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

