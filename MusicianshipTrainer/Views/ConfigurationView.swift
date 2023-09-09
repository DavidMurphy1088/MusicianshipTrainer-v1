import SwiftUI
import CoreData
import SwiftUI

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @State var colorScore:Color
    @State var colorBackground:Color
    @State var colorInstructions:Color// = Color.white
    @State private var selectedOption: Int? = nil
    @State var ageGroup:AgeGroup
    @State var selectedAge:Int = 0
    let ages = ["5-10", "11Plus"]

    var body: some View {
        //GeometryReader { geo in //CAUSES ALL CHILDS LEft ALIGNED???
            VStack(alignment: .center) {
                
                Text("Your Configuration").font(.title).padding()

//                VStack {
//                    Text("Select Your Instrument")
//                    ConfigSelectInstrument()
//                }
//                .frame(width: 100, height: 100)
                
                // =================== Age Mode ===================
                
                VStack {
                    Text("Select Your Age Group").font(.title)
                    ConfigSelectAgeMode(selectedIndex: $selectedAge, items: ages)
                }
                //.frame(width: 300, height: 100)
                //.padding()
                .border(Color.black, width: 1)
                .padding()
                .onAppear {
                    if ageGroup == .Group_5To10 {
                        selectedAge = 0
                    }
                    else {
                        selectedAge = 1
                    }
                    //print("OnAppear", selectedAge)
                }
                
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
                        
                        UIGlobals.ageGroup = selectedAge == 0 ? .Group_5To10 : .Group_11Plus
                        //print("Save Config", selectedAge, UIGlobals.ageGroup)
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
//
//struct ConfigSelectInstrument: View {
//    @Binding var selectedIndex: Int
//    let items: [String]
//
//    var body: some View {
//        Picker("Select your Age", selection: $selectedIndex) {
//            ForEach(0..<items.count) { index in
//                Text(items[index]).tag(index)
//            }
//        }
//        .pickerStyle(DefaultPickerStyle())
//    }
//
//}

struct ConfigSelectAgeMode: View {
    @Binding var selectedIndex: Int
    let items: [String]

    var body: some View {
        Picker("Select your Age", selection: $selectedIndex) {
            let total = items.count
            ForEach(0..<total) { index in
                Text(items[index]).tag(index).font(.title)
            }
        }
        //.pickerStyle(DefaultPickerStyle())
        .pickerStyle(InlinePickerStyle())
    }
}

