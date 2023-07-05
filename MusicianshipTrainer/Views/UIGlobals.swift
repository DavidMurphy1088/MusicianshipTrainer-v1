import SwiftUI
import CoreData

class UIGlobals {
    static let backgroundColorLighter = Color.blue.opacity(0.03)
    static let backgroundColor = Color.blue.opacity(0.10) //0.04
    //static let backgroundColorDarker = Color.blue.opacity(0.04)
    
    static let cornerRadius:CGFloat = 16
    static let borderColor:CGColor = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    static let borderLineWidth:CGFloat = 2
    static let buttonCornerRadius = 10.0
    static let practiceTipsColor = Color.blue.opacity(0.08) //UIColor(red: 200/255, green: 255/255, blue: 200/255, alpha: 1) //paleGreen
}

struct StandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

//Button(action: {
//}) {
//    Text("Click Me")
//}
//.StandardButtonStyle(CustomButtonStyle())

//    .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(Color.white, lineWidth: 2)
//                )
