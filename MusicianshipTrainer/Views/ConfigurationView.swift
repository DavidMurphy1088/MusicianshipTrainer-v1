import SwiftUI
import CoreData
import SwiftUI

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        //GeometryReader { geo in //CAUSES ALL CHILDS LEft ALIGNED???
            VStack(alignment: .center) {
                
                HStack(alignment: .center) {
                    Image("nzmeb_logo_transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                    Text("Configuration").font(.title).padding()
                }
                .overlay(
                    RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                )
                .background(UIGlobals.backgroundColor)
                //.padding()
                
                ConfigSelectInstrument().padding()
                
                //ContentView2()
                Button("Cancel") {
                    isPresented = false
                }
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

                Text("Musicianship Trainer - Version.Build \(appVersion).\(buildNumber)").font(.headline).padding()
                
                //ContentView()
                
                //VoiceListView()
            }
       // }
    }
}

struct ConfigSelectInstrument: View {
    let options = ["Piano", "Vocal", "Violin", "Guitar"]
    @State private var selectedOption: String?
    @State private var isShowingSelection = false
    
    var body: some View {
        VStack {
            //Text("Selected Option: \(selectedOption ?? "None")")
            Button("Select Instrument") {
                isShowingSelection = true
            }
            .sheet(isPresented: $isShowingSelection) {
               // OptionSelectionView(selectedOption: $selectedOption)
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
