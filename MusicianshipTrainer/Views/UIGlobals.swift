import SwiftUI
import CoreData

class UIGlobals {
    static var colorDefault = Color.blue.opacity(0.10)
    static var colorBackgroundDefault = Color.white

    static var colorScore = UIGlobals.colorDefault
    static var colorInstructions = UIGlobals.colorDefault
    static var colorBackground = colorBackgroundDefault

    //static var backgroundColorHiliteBox = Color.blue.opacity(0.10) //0.04
    //static let backgroundColorLighter = Color.blue.opacity(0.03)
    
    //static let cornerRadius:CGFloat = 16
    static let cornerRadius:CGFloat = 8
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

extension Text {
    
    func defaultStyle() -> some View {
        self
            .foregroundColor(.white)
        //UIDevice.current.userInterfaceIdiom == .phone ? .zero : .
            .padding(UIDevice.current.userInterfaceIdiom == .phone ? 2 : 12)
            .background(.blue)
            .cornerRadius(UIGlobals.cornerRadius)
            //.padding()
    }
    
    func defaultContainer(selected:Bool) -> some View {
        self
            .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Color.black : Color.clear, lineWidth: 1)
                //.background(selectedIntervalIndex == index ? Color(.systemTeal) : Color.clear)
                .background(selected ? UIGlobals.colorInstructions : Color.clear)
        )

    }
}


