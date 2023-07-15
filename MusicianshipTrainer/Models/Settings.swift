import Foundation
import SwiftUI

enum UserDefaultKeys {
    static let selectedColorScore = "SelectedColorScore"
    static let selectedColorInstructions = "SelectedColorInstructions"
}

extension UserDefaults {
    func setSelectedColor(key:String, _ color: Color) {
        set(color.rgbData, forKey: key)
    }

    func getSelectedColor(key:String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        return Color.rgbDataToColor(data)
    }
}

extension Color {
    var rgbData: Data {
        let uiColor = UIColor(self)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        return data ?? Data()
    }
    
    static func rgbDataToColor(_ data: Data) -> Color? {
        guard let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return nil
        }
        return Color(uiColor)
    }
}

class Settings {
    static let shared = Settings()
    let id = UUID()
    
    init() {
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorScore) {
            print("Retrieved color: \(retrievedColor)")
            UIGlobals.colorScore = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorInstructions) {
            print("Retrieved color: \(retrievedColor)")
            UIGlobals.colorInstructions = retrievedColor
        }
    }
    
    func saveColours() {
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorScore, UIGlobals.colorScore)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorInstructions, UIGlobals.colorInstructions)
    }
}
