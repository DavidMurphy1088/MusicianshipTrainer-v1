import SwiftUI
import FirebaseCore
import AVFoundation
import GoogleSignIn
//import GoogleAPIClientForREST

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Logger.logger.log(self, "Firebase Configured" )
        //print(FirebaseApp.defaultOptions)
        //FirebaseConfiguration.shared.setLoggerLevel(<#FirebaseLoggerLevel#>)
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        Logger.logger.log(self, "Version.Build \(appVersion).\(buildNumber)")
//        let user: GIDGoogleUser = GIDGoogleUser()
//        user.userID = ""
//        GIDSignIn.sharedInstance.currentUser = user // .clientID = "YOUR_CLIENT_ID"
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
              // Show the app's signed-out state.
            } else {
              // Show the app's signed-in state.
            }
          }
        return true
    }
    
    func application(_ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
      var handled: Bool

      handled = GIDSignIn.sharedInstance.handle(url)
      if handled {
        return true
      }

      // Handle other custom URL types.

      // If not handled by this app, return false.
      return false
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
    static let productionMode = false
    //static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Musicianship")
    //product licensed by grade 14Jun23
    static let root:ContentSection = ContentSection(parent: nil, type: ContentSection.SectionType.none, name: "Grade 1")
    var launchTimeSecs = 2.5
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                
                if launchScreenState.state == .finished {
                    if exampleData.dataStatus == GoogleSpreadsheet.DataStatus.ready {
                        if MusicianshipTrainerApp.productionMode {
                            TopicsNavigationView(topic: MusicianshipTrainerApp.root)
                                .tabItem {Label("Exercises", image: "music.note")
                                }
                        }
                        else {
                            IndexView()
                        }
                    }
                    else {
                        if exampleData.dataStatus == GoogleSpreadsheet.DataStatus.waiting {
                            Spacer()
                            Image(systemName: "hourglass.tophalf.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                            //.scaleEffect(2.0)
                                .foregroundColor(Color.blue)
                                .padding()
                            Text("")
                            Text("Loading Content...").font(.headline)
                            Spacer()
                        }
                        else {
                            Text("Sorry, we could not create an internet conection.").font(.headline).foregroundColor(.red)
                            Text("Please try again.").font(.headline).foregroundColor(.red)
                        }
                    }
                }
                if MusicianshipTrainerApp.productionMode {
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
            .onOpenURL { url in
              GIDSignIn.sharedInstance.handle(url)
            }

        }
    }
}

