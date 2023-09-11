import SwiftUI
import CoreData

enum AgeGroup: Int {
    case Group_5To10 = 0
    case Group_11Plus = 1
}

class UIGlobals {
    static var colorDefault = Color.blue.opacity(0.10)
    static var colorBackgroundDefault = Color.white

    static var colorScore = UIGlobals.colorDefault
    static var colorInstructions = UIGlobals.colorDefault
    static var colorBackground = colorBackgroundDefault

    static let cornerRadius:CGFloat = 8
    static let borderColor:CGColor = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    static let borderLineWidth:CGFloat = 2
    static let buttonCornerRadius = 10.0
    static let practiceTipsColor = Color.blue.opacity(0.08) //UIColor(red: 200/255, green: 255/255, blue: 200/255, alpha: 1) //paleGreen
    
    static var ageGroup:AgeGroup = .Group_11Plus
    static let font = Font.custom("Lora", size: 24)
    static let navigationFont = Font.custom("Lora", size: 32)

    static func getAgeGrpup() -> String {
        return UIGlobals.ageGroup == .Group_11Plus ? "11Plus" : "5-10"
    }
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
    
    func defaultButtonStyle() -> some View {
        self
            .font(UIGlobals.font)
            .foregroundColor(.white)
            .padding(UIDevice.current.userInterfaceIdiom == .phone ? 2 : 12)
            .background(.blue)
            .cornerRadius(UIGlobals.cornerRadius)
    }
    
    func defaultTextStyle() -> some View {
        self
            .font(UIGlobals.font)
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

class UICommons {
    static let buttonCornerRadius:Double = 20.0
    static let buttonPadding:Double = 8
    static let colorAnswer = Color.green.opacity(0.4)
}


struct UIHiliteText : View {
    @State var text:String
    @State var answerMode:Int?
    
    var body: some View {
        Text(text)
        .foregroundColor(.black)
        .padding(UICommons.buttonPadding)
        .background(
            RoundedRectangle(cornerRadius: UICommons.buttonCornerRadius, style: .continuous).fill(answerMode == nil ? Color.blue.opacity(0.4) : UICommons.colorAnswer)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UICommons.buttonCornerRadius, style: .continuous).strokeBorder(Color.blue, lineWidth: 1)
        )
        .padding()
    }
    
}


