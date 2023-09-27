import SwiftUI
import CoreData

enum AgeGroup: Int {
    case Group_5To10 = 0
    case Group_11Plus = 1
}

class UIGlobals {
    static var colorDefault = Color.white
    
    static var colorInstructionsDefault = Color.blue.opacity(0.10)
    static var colorBackgroundDefault = Color(red: 1.0, green: 1.0, blue: 0.95)
    static var colorScoreDefault = Color(red: 0.85, green: 1.0, blue: 1.0)
    static var colorNavigationDefault = Color(red: 0.95, green: 1.0, blue: 1.0)

    static var colorScore = colorScoreDefault
    static var colorInstructions = colorInstructionsDefault
    
    ///Color of each test's screen background
    //static var colorBackground = colorBackgroundDefault
    static var colorBackground = Color(red: 0.0, green: 0.0, blue: 0.7)

    ///Color of each navigation row in Navigation View. But there is still a navigation color behind these from the NavigationView
    //static var colorNavigation = colorBackgroundDefault //colorNavigationDefault
    //static var colorNavigation = Color(red: 0.0, green: 0.7, blue: 0.0)
    
    ///Behind instructions to match background of the Navigation View below which is unchangeable from grey
    //static var colorNavigationBackground = Color(red: 0.95, green: 0.95, blue: 0.95)
    //static var colorNavigationBackground = Color(red: 0.7, green: 0.0, blue: 0.0)

    static let cornerRadius:CGFloat = 8
    static let borderColor:CGColor = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    static let borderLineWidth:CGFloat = 2
    static let buttonCornerRadius = 10.0
    static let practiceTipsColor = Color.blue.opacity(0.08) //UIColor(red: 200/255, green: 255/255, blue: 200/255, alpha: 1) //paleGreen
    
    static let circularIconSize = 40.0
    static let circularIconBorderSize = 4.0

    static var ageGroup:AgeGroup = .Group_11Plus
    static let font = Font.custom("Lora", size: 24)
    static let fontiPhone = Font.custom("Lora", size: 16)

    //static let navigationFont = Font.custom("Lora", size: 32)
    static let navigationFont = Font.custom("Courgette-Regular", size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 20)
        
    static func getAgeGroup() -> String {
        return UIGlobals.ageGroup == .Group_11Plus ? "11Plus" : "5-10"
    }
    
    static func showDeviceOrientation() {
        let orientation = UIDevice.current.orientation
        print("showDeviceOrientation --> IS PORTRAIT", orientation.isPortrait,"IS LANDSCAPE", orientation.isLandscape,
              "isGeneratingDeviceOrientationNotifications", UIDevice.current.isGeneratingDeviceOrientationNotifications,
              "RAW", orientation.rawValue)
        switch orientation {
        case .portrait:
            print("Portrait")
        case .portraitUpsideDown:
            print("Portrait Upside Down")
        case .landscapeLeft:
            print("Landscape Left")
        case .landscapeRight:
            print("Landscape Right")
        case .faceUp:
            print("Face Up")
        case .faceDown:
            print("Face Down")
        default:
            print("Unknown")
        }
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
            .font(UIDevice.current.userInterfaceIdiom == .pad ? UIGlobals.font : UIGlobals.fontiPhone)
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


