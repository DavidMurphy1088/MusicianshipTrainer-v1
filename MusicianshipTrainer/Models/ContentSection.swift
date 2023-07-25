import Foundation
import AVFoundation

/// The mode of the test and the navigation allowed from it
class TestMode : ObservableObject {
    enum Mode {
        case practice
        case exam
    }
//    enum ContentSectionNavigationPolicy {
//        case must
//        case cannot
//        case can
//    }
    var mode:Mode
    //var navigationPolicy:ContentSectionNavigationPolicy
    
    init(mode:Mode) {//}, navigationPolicy:ContentSectionNavigationPolicy) {
        self.mode = mode
        //self.navigationPolicy = navigationPolicy
    }
}

class ContentSection: Identifiable {
    let id = UUID()
    var name: String = ""
    var type:String = ""
    var subSections:[ContentSection] = []
    var parent:ContentSection?
    var isActive:Bool
    var level:Int
    //var instructions:String?
    //var tipsAndTricks:String?
    var loadedDictionaryKey:String
    var loadedRow:Int
    var index:Int
    
    init(parent:ContentSection?, name:String, type:String, loadedDictionaryKey:String, loadedRow:Int, isActive:Bool = true) {
        self.parent = parent
        self.name = name
        self.isActive = isActive
        self.type = type
        var par = parent
        var level = 0
        var path = name
        while par != nil {
            level += 1
            path = par!.name+"."+path
            par = par!.parent
        }
        self.level = level
        self.loadedDictionaryKey = loadedDictionaryKey
        self.loadedRow = loadedRow
        self.index = 0
    }
    
    func getTitle() -> String {
        if let path = Bundle.main.path(forResource: "NameToTitleMap", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            if let stringValue = dict[self.name] as? String {
                return stringValue
            }
        }
        
        // remove leading zero in example number
        if let range = name.range(of: "example", options: .caseInsensitive) {
            let substrings = name.components(separatedBy: " ")
            if substrings.count > 1 {
                let numStr = substrings[1]
                if numStr.first == "0" {
                    let num = Int(numStr)
                    if let num = num {
                        return substrings[0] + " \(num)"
                    }
                }
            }
        }

        //print("==========getTitte no Map", self.name, self.level)
        return self.name
    }
    
    func getPath() -> String {
        var path = ""
        var section = self
        while true {
            path = section.name + path
            if let parent = section.parent {
                section = parent
                if parent.parent != nil {
                    path = "." + path
                }                
            }
            else {
                break
            }
        }
        return path
    }
    
    func getPathTitle() -> String {
        var title = ""
        var section = self
        while true {
            title = section.getTitle() + title
            if let parent = section.parent {
                section = parent
                if parent.parent != nil {
                    title = "." + title
                }
            }
            else {
                break
            }
        }
        return title
    }

    func getChildSectionByType(type: String) -> ContentSection? {
        for child in self.subSections {
            if child.type == type {
                return child
            }
        }
        return nil
    }
    
    func isExamMode() -> Bool {
        let path:String = self.getPath()
        let exam = path.uppercased().contains("EXAM MODE")
        return exam
    }
}

class Syllabus {
    static public let shared = Syllabus()
}
