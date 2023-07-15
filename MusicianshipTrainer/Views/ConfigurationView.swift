import SwiftUI
import CoreData
import SwiftUI

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @State var colorScore:Color
    @State var colorInstructions:Color// = Color.white

    var body: some View {
        //GeometryReader { geo in //CAUSES ALL CHILDS LEft ALIGNED???
            VStack(alignment: .center) {
                
//                HStack(alignment: .center) {
//                    Image("nzmeb_logo_transparent")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 64)
                    Text("Configuration").font(.title).padding()
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
                            .fill(colorScore)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Score : Select a Colour", selection: $colorScore, supportsOpacity: false)
                            //.padding()
                        
                        Button("Reset") {
                            colorScore = UIGlobals.colorDefault
                        }
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding()
                    
                    VStack {
                        Circle()
                            .fill(colorInstructions)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Instructions : Select a Colour", selection: $colorInstructions, supportsOpacity: false)
                            //.padding()
                        Button("Reset") {
                            colorInstructions = UIGlobals.colorInstructions
                        }

                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding()
                }

                
                //ContentView2()
                
                HStack {
                    Button("Ok") {
                        UIGlobals.colorScore = colorScore
                        UIGlobals.colorInstructions = colorInstructions
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
                    Text("© 2023 MusicMaster LLC.").font(.headline)
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

//struct OptionSelectionView: View {
//    let metro = Metronome.getMetronomeWithCurrentSettings()
//    @Binding var selectedOption: String?
//    @Environment(\.presentationMode) var presentationMode
//
//    var body: some View {
//        List {
//            ForEach(metro.soundFontNames.indices, id: \.self) { index in
//                Button(action: {
//                    metro.samplerFileName = metro.soundFontNames[index].1
//                    //if let presentationMode = presentationMode {
//                                presentationMode.wrappedValue.dismiss()
//                            //}
//
//                }) {
//                    VStack(alignment: .leading) {
//                        Text("Index: \(metro.soundFontNames[index].0)")
//                     }
//                }
//            }
//        }
//        .navigationTitle("Select Instrument")
//    }
//}
