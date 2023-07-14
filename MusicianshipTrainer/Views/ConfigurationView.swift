import SwiftUI
import CoreData
import SwiftUI

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @State private var selectedColorMenus = Color.white
    @State private var selectedColorExamples = Color.white

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
                
                // =================== Colors ===================
                
                HStack {
                    VStack {
                        Circle()
                            .fill(selectedColorMenus)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Menus : Select a Color", selection: $selectedColorMenus, supportsOpacity: false)
                            .padding()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding()
                    
                    VStack {
                        Circle()
                            .fill(selectedColorExamples)
                            .frame(width: 100, height: 100)
                        
                        ColorPicker("Examples : Select a Color", selection: $selectedColorExamples, supportsOpacity: false)
                            .padding()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding()
                }


                ConfigSelectInstrument().padding()
                
                //ContentView2()
                HStack {
                    Button("Ok") {
                        UIGlobals.backgroundColorMenus = selectedColorMenus
                        UIGlobals.backgroundColorHiliteBox = selectedColorExamples
                        UserDefaults.standard.setSelectedColor(selectedColorExamples)
                        //                    if let retrievedColor = UserDefaults.standard.getSelectedColor() {
                        //                        print("Retrieved color: \(retrievedColor)")
                        //                    }
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

                Text("Musicianship Trainer - Version.Build \(appVersion).\(buildNumber)").font(.headline).padding()
                
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
