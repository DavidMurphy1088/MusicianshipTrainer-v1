import SwiftUI
import CoreData
import SwiftUI

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @State var colorScore:Color
    @State var colorBackground:Color
    @State var colorInstructions:Color// = Color.white

    var body: some View {
        //GeometryReader { geo in //CAUSES ALL CHILDS LEft ALIGNED???
            VStack(alignment: .center) {
                
//                HStack(alignment: .center) {
//                    Image("nzmeb_logo_transparent")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 64)
                    Text("Your Preferences").font(.title).padding()
//                }
//                .overlay(
//                    RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
//                )
//                .background(UIGlobals.backgroundColorHiliteBox)
//                //.padding()
                
                VStack {
                    Text("Select Your Instrument")
                    ConfigSelectInstrument()
                }
                .frame(width: 100, height: 100)
                
                // =================== Colors ===================
                
                HStack {
                    VStack {
                        Circle()
                            .fill(colorBackground)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Background : Select a Colour", selection: $colorBackground, supportsOpacity: false)
                        
                        Button("Reset") {
                            colorBackground = UIGlobals.colorBackgroundDefault
                        }
                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()

                    VStack {
                        Circle()
                            .fill(colorScore)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Score : Select a Colour", selection: $colorScore, supportsOpacity: false)
                        
                        Button("Reset") {
                            colorScore = UIGlobals.colorDefault
                        }
                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()

                    VStack {
                        Circle()
                            .fill(colorInstructions)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Instructions : Select a Colour", selection: $colorInstructions, supportsOpacity: false)

                        Button("Reset") {
                            colorInstructions = UIGlobals.colorInstructions
                        }

                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)).padding()
                }

                
                //ContentView2()
                
                HStack {
                    Button("Ok") {
                        UIGlobals.colorScore = colorScore
                        UIGlobals.colorInstructions = colorInstructions
                        UIGlobals.colorBackground = colorBackground
                        Settings.shared.saveColours()
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

struct ConfigSelectInstrument: View {
    let options = ["Piano", "Vocal", "Violin", "Guitar"]
    @State private var selectedOption: String?
    
    var body: some View {
        VStack {
            VStack {
                Picker("Select an option", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.wheel)
                
            }
        }
    }
}

