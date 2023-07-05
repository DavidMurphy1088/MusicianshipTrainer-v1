import Foundation
import SwiftUI

enum LaunchScreenStep {
    case firstStep
    case secondStep
    case finished
}

final class LaunchScreenStateManager: ObservableObject {

@MainActor @Published private(set) var state: LaunchScreenStep = .firstStep
    @MainActor func dismiss() {
        Task {
            state = .secondStep
            //try? await Task.sleep(for: Duration.seconds(1))
            sleep(1)
            self.state = .finished
        }
    }
}

class Opacity : ObservableObject {
    @Published var imageOpacity: Double = 0.0
    var launchTimeSecs:Double
    var timer:Timer?
    var ticksPerSec = 30.0
    var duration = 0.0
    
    init(launchTimeSecs:Double) {
        self.launchTimeSecs = launchTimeSecs
        let timeInterval = 1.0 / ticksPerSec
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let opacity = sin((self.duration * Double.pi * 1.0) / self.launchTimeSecs)
                self.imageOpacity = opacity
                //print("called", self.duration, "opacity", String(format: "%.2f", opacity))
                if self.duration >= self.launchTimeSecs {
                    self.timer?.invalidate()
                }
                self.duration += timeInterval
            }
        }
    }

}

struct LaunchScreenView: View {
    @ObservedObject var opacity:Opacity
    @State var durationSeconds:Double
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1
    
    init(launchTimeSecs:Double) {
        self.opacity = Opacity(launchTimeSecs: launchTimeSecs)
        self.durationSeconds = launchTimeSecs
    }

    func appVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(appVersion).\(buildNumber)"
    }
    
    @ViewBuilder
    private var image: some View {  // Mark 3
        GeometryReader { geo in
            ZStack {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("nzmeb_logo_transparent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.75)
                            .opacity(self.opacity.imageOpacity)
                        //.border(Color(.red))
                        Spacer()
                    }
                    Spacer()
                }
                VStack(alignment: .center) {
                    Text("NZMEB Musicianship Trainer")
                        //.font(.headline)
                        .font(.title)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.85)
                        .opacity(self.opacity.imageOpacity)
                    Text("Version \(appVersion())")
                }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundColor: some View {  // Mark 3
        //Color.orange.ignoresSafeArea()
        //Color.cyan.ignoresSafeArea()
        //Color.gray.ignoresSafeArea()
        //Color.blue.ignoresSafeArea()
        //Color.secondary.ignoresSafeArea()
        Color(red: 150 / 255, green: 210 / 255, blue: 225 / 255).ignoresSafeArea()
    }
    
    var body: some View {
        ZStack {
            //backgroundColor  // Mark 3
            image  // Mark 3
        }
    }
    
}

