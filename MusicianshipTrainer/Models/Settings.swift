import Foundation
import SwiftUI

enum UserDefaultKeys {
    static let selectedColorScore = "SelectedColorScore"
    static let selectedColorInstructions = "SelectedColorInstructions"
    static let selectedColorBackground = "SelectedColorBackground"
    static let selectedAgeGroup = "SelectedAgeGroup"
    static let showReloadHTMLButton = "showReloadHTMLButton"
    static let useTestData = "useTestData"
    static let useAnimations = "useAnimations"
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
    
//    func setShowReloadHTMLButton(key:String, _ way: Bool) {
//        set(way, forKey: key)
//        log()
//    }
    
    func setBoolean(key:String, _ way: Bool) {
        set(way, forKey: key)
    }
    
    func getBoolean(key:String) -> Bool {
        return bool(forKey: key)
    }
    
    func getUseTestData(key:String) -> Bool {
        return bool(forKey: key)
    }
    
    func log() {
        let userDefaults = UserDefaults.standard
        let allValues = userDefaults.dictionaryRepresentation()

        for (key, value) in allValues {
            print("Key: \(key), Value: \(value)")
        }
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
    static var useTestData = false
    static var showReloadHTMLButton = false
    static var useAnimations = false
    
    static var ageGroup:AgeGroup = .Group_11Plus
    static var colorScore = UIGlobals.colorScoreDefault
    static var colorInstructions = UIGlobals.colorInstructionsDefault
    ///Color of each test's screen background
    static var colorBackground = UIGlobals.colorBackgroundDefault
    static let AgeGroup11Plus = "11Plus"
    
    static let shared = Settings()
    let id = UUID()
    
    init() {
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorScore) {
            Settings.colorScore = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorInstructions) {
            Settings.colorInstructions = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorBackground) {
            Settings.colorBackground = retrievedColor
        }
        if let retrievedAgeGroup = UserDefaults.standard.getSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup) {
            Settings.ageGroup = retrievedAgeGroup
        }
        Settings.showReloadHTMLButton = UserDefaults.standard.getBoolean(key: UserDefaultKeys.showReloadHTMLButton)
        Settings.useTestData = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useTestData)
        Settings.useAnimations = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useAnimations)
    }
    
    static func getAgeGroup() -> String {
        return Settings.ageGroup == .Group_11Plus ? AgeGroup11Plus : "5-10"
    }

    func saveConfig() {
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorScore, Settings.colorScore)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorInstructions, Settings.colorInstructions)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorBackground, Settings.colorBackground)
        UserDefaults.standard.setSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup, Settings.ageGroup)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.showReloadHTMLButton, Settings.showReloadHTMLButton)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useTestData, Settings.useTestData)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useAnimations, Settings.useAnimations)
    }
    
}
