import SwiftUI
import FirebaseCore
import AVFoundation

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
        let settings:Settings = Settings.shared
        
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
    @ObservedObject var logger = Logger.logger
    static let productionMode = true
    @ObservedObject var exampleData = ExampleData.shared1
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Musicianship")
    //product licensed by grade 14Jun23
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Grade 1")
    static let root:ContentSection = ContentSection(parent: nil, name: "", type: "")
    static let settings:Settings = Settings.shared
    var launchTimeSecs = 2.5

    init() {
//        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
//            print("\(key) = \(value) \n")
//        }
//        let fileManager = FileManager.default
//        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL,
//                                                            includingPropertiesForKeys: nil)
//            for fileURL in fileURLs {
//                print(fileURL)
//            }
//        } catch {
//            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
//        }
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

