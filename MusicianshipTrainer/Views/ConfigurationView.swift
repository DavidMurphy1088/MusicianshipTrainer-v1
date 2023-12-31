import SwiftUI
import CoreData
import SwiftUI

struct LogView: View {
    let items: [LogMessage] = Logger.logger.recordedMsgs
    
    var body: some View {
        Text("Log messages")
        ScrollView {
            VStack(spacing: 20) {
                ForEach(items) { item in
                    HStack {
                        Text(item.message).padding(0)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var settings:Settings
    //let ages = ["5-10", "11Plus"]
    let colorCircleSize = 60.0
    
    var body: some View {
        VStack(alignment: .center) {
            
            Text("Configuration").font(.title).padding()
                //.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                .padding()

            // ------------------- Colors ----------------
            
            HStack {
                VStack {
                    Circle()
                        .fill(settings.colorBackground)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    
                    ColorPicker("Background\nSelect a Colour", selection: $settings.colorBackground, supportsOpacity: false)
                    
                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorBackground = UIGlobals.colorBackgroundDefault
                        }
                    }
                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()

                VStack {
                    Circle()
                        .fill(settings.colorScore)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    
                    ColorPicker("Score\nSelect a Colour", selection: $settings.colorScore, supportsOpacity: false)
                    
                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorScore = UIGlobals.colorScoreDefault
                        }
                    }
                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()

                VStack {
                    Circle()
                        .fill(settings.colorInstructions)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    
                    ColorPicker("Instructions\nSelect a Colour", selection: $settings.colorInstructions, supportsOpacity: false)

                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorInstructions = UIGlobals.colorInstructionsDefault
                        }
                    }

                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()
            }
            
            VStack {
                HStack {
                    HStack {
                        Text("Select Your Age Group")
                        ConfigSelectAgeMode(selectedIndex: $settings.ageGroup)
                    }
                    .onAppear {
//                            if settings.ageGroup == .Group_5To10 {
//                                settings.selectedAge = .G
//                            }
//                            else {
//                                settings.selectedAge = 1
//                            }
                    }
                    //.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useAnimations.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useAnimations ? "checkmark.square" : "square")
                            Text("Show Animations for Answers")
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.soundOnTaps.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.soundOnTaps ? "checkmark.square" : "square")
                            //let x = settings.soundOnTaps ? 0 : 1
                            Text("Drum Sound On For Rhythm Tests")
                        }
                    }
                    .padding()
                    
//                    Button(action: {
//                        DispatchQueue.main.async {
//                            settings.useUpstrokeTaps.toggle()
//                        }
//                    }) {
//                        HStack {
//                            Image(systemName: settings.useUpstrokeTaps ? "checkmark.square" : "square")
//                            Text("Use Upstroke Taps")
//                        }
//                    }
//                    .padding()
                }
                
                HStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.showReloadHTMLButton.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.showReloadHTMLButton ? "checkmark.square" : "square")
                            Text("Show Reload HTML Button")
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useTestData.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useTestData ? "checkmark.square" : "square")
                            Text("Use Test Data")
                        }
                    }
                    .padding()
                }
            }
            
            //LogView().border(.black).padding()
            HStack {
                Button("Ok") {
                    Settings.shared = Settings(copy: settings)
                    Settings.shared.saveConfig()
                    isPresented = false
                }
                .padding()
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

            VStack {
                Text("Musicianship Trainer - Version.Build \(appVersion).\(buildNumber)").font(.headline)
                Text("© 2024 Musicmaster Education LLC.").font(.headline)
            }
        }
    }
}

//struct ConfigSelectAgeMode: View {
//    @Binding var selectedIndex: AgeGroup
//    let items: [String]
//
//    var body: some View {
//        Picker("Select your Age", selection: $selectedIndex) {
//            ForEach(0..<items.count) { index in
//                Text(items[index]).tag(index).font(.title)
//            }
//        }
//        .pickerStyle(DefaultPickerStyle())
//        //.pickerStyle(InlinePickerStyle())
//    }
//}

struct ConfigSelectAgeMode: View {
    @Binding var selectedIndex: AgeGroup

    var body: some View {
        Picker("Select your Age", selection: $selectedIndex) {
            ForEach(AgeGroup.allCases) { ageGroup in
                Text(ageGroup.displayName).tag(ageGroup).font(.title)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        // .pickerStyle(InlinePickerStyle())
    }
}
