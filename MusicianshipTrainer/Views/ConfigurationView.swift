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
    @State var colorScore:Color
    @State var colorBackground:Color
    @State var colorInstructions:Color
    @State var showReloadHTMLButton: Bool
    @State var useAnimations: Bool
    @State var useTestData: Bool

    @State private var selectedOption: Int? = nil
    @State var ageGroup:AgeGroup
    @State var selectedAge:Int = 0
        
    let ages = ["5-10", "11Plus"]
    let colorCircleSize = 60.0
    
    var body: some View {
        //GeometryReader { geo in //CAUSES ALL CHILDS LEft ALIGNED???
            VStack(alignment: .center) {
                
                Text("Your Configuration").font(.title).padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                    .padding()
                
                // ------------ Age Mode ---------------
                
                VStack {
                    Text("Select Your Age Group").font(.title).padding()
                    ConfigSelectAgeMode(selectedIndex: $selectedAge, items: ages)
                }
                .onAppear {
                    if ageGroup == .Group_5To10 {
                        selectedAge = 0
                    }
                    else {
                        selectedAge = 1
                    }
                }
//                .overlay(
//                    RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
//                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                .padding()
                
                // ------------------- Colors ----------------
                
                HStack {
                    VStack {
                        Circle()
                            .fill(colorBackground)
                            .frame(width: colorCircleSize, height: colorCircleSize)
                        
                        ColorPicker("Background\nSelect a Colour", selection: $colorBackground, supportsOpacity: false)
                        
                        Button("Reset") {
                            colorBackground = UIGlobals.colorBackgroundDefault
                        }
                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()

                    VStack {
                        Circle()
                            .fill(colorScore)
                            .frame(width: colorCircleSize, height: colorCircleSize)
                        
                        ColorPicker("Score\nSelect a Colour", selection: $colorScore, supportsOpacity: false)
                        
                        Button("Reset") {
                            colorScore = UIGlobals.colorDefault
                        }
                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()

                    VStack {
                        Circle()
                            .fill(colorInstructions)
                            .frame(width: colorCircleSize, height: colorCircleSize)
                        
                        ColorPicker("Instructions\nSelect a Colour", selection: $colorInstructions, supportsOpacity: false)

                        Button("Reset") {
                            colorInstructions = Settings.colorInstructions
                        }

                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()
                }
                
                Button(action: {
                    useAnimations.toggle()
                }) {
                    HStack {
                        Image(systemName: useAnimations ? "checkmark.square" : "square")
                        Text("Show Animations for Answers?")
                    }
                }
                .padding()
                
                Button(action: {
                    showReloadHTMLButton.toggle()
                }) {
                    HStack {
                        Image(systemName: showReloadHTMLButton ? "checkmark.square" : "square")
                        Text("Show Reload HTML Button?")
                    }
                }
                .padding()
                
                Button(action: {
                    useTestData.toggle()
                }) {
                    HStack {
                        Image(systemName: useTestData ? "checkmark.square" : "square")
                        Text("Use Test Data?")
                    }
                }
                .padding()
                
                //LogView().border(.black).padding()
                HStack {
                    Button("Ok") {
                        Settings.colorScore = colorScore
                        Settings.colorInstructions = colorInstructions
                        Settings.colorBackground = colorBackground
                        
                        Settings.ageGroup = selectedAge == 0 ? .Group_5To10 : .Group_11Plus
                        Settings.showReloadHTMLButton = showReloadHTMLButton
                        Settings.useAnimations = useAnimations
                        Settings.useTestData = useTestData
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
                    Text("© 2023 Musicmaster Education LLC.").font(.headline)
                }
            }
        //}
    }
    
}

struct ConfigSelectAgeMode: View {
    @Binding var selectedIndex: Int
    let items: [String]

    var body: some View {
        Picker("Select your Age", selection: $selectedIndex) {
            ForEach(0..<items.count) { index in
                Text(items[index]).tag(index).font(.title)
            }
        }
        //.pickerStyle(DefaultPickerStyle())
        //.pickerStyle(InlinePickerStyle())
    }
}

