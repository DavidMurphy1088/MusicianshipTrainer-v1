import Foundation
import SwiftUI

enum UserDefaultKeys {
    static let selectedColorScore = "SelectedColorScore"
    static let selectedColorInstructions = "SelectedColorInstructions"
    static let selectedColorBackground = "SelectedColorBackground"
    static let selectedAgeGroup = "SelectedAgeGroup"
}

extension UserDefaults {
    func setSelectedColor(key:String, _ color: Color) {
        set(color.rgbData, forKey: key)
    }

    func getSelectedColor(key:String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        return Color.rgbDataToColor(data)
    }
    
    func setSelectedAgeGroup(key:String, _ ageGroup: AgeGroup) {
        var age = 0
        if ageGroup == .Group_5To10 {
            age = 0
        }
        else {
            age = 1
        }
        
        let data = withUnsafeBytes(of: age) { Data($0) }
        set(data, forKey: key)
    }

    func getSelectedAgeGroup(key:String) -> AgeGroup? {
        guard let data = data(forKey: key) else { return nil }
        let age  = data.withUnsafeBytes { $0.load(as: Int.self) }
        return age == 0 ? .Group_5To10 : .Group_11Plus
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
            UIGlobals.colorScore = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorInstructions) {
            UIGlobals.colorInstructions = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorBackground) {
            UIGlobals.colorBackground = retrievedColor
        }
        if let retrievedAgeGroup = UserDefaults.standard.getSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup) {
            UIGlobals.ageGroup = retrievedAgeGroup
        }
    }
    
    func saveConfig() {
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorScore, UIGlobals.colorScore)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorInstructions, UIGlobals.colorInstructions)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorBackground, UIGlobals.colorBackground)
        UserDefaults.standard.setSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup, UIGlobals.ageGroup)
    }
    
}
