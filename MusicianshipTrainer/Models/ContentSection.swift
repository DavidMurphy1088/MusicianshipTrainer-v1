import Foundation
import AVFoundation

class ContentSection: Identifiable {
    let id = UUID()
    var name: String = ""
    var type:String = ""
    var subSections:[ContentSection] = []
    var parent:ContentSection?
    var isActive:Bool
    var level:Int
    var instructions:String?
    var tipsAndTricks:String?

    init(parent:ContentSection?, name:String, type:String, instructions:String?, tipsAndTricks:String?, isActive:Bool = true) {
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
        self.instructions = instructions
        self.tipsAndTricks = tipsAndTricks
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

    func getChildSectionByName(name: String) -> ContentSection? {
        for child in self.subSections {
            if child.name == name {
                return child
            }
        }
        return nil
    }
}

class Syllabus {
    static public let shared = Syllabus()
}
