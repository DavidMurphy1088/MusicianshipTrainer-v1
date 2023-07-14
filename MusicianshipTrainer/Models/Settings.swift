import Foundation
import SwiftUI

enum UserDefaultKeys {
    static let selectedColor = "SelectedColor"
}

extension UserDefaults {
    func setSelectedColor(_ color: Color) {
        set(color.rgbData, forKey: UserDefaultKeys.selectedColor)
    }

    func getSelectedColor() -> Color? {
        guard let data = data(forKey: UserDefaultKeys.selectedColor) else { return nil }
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
