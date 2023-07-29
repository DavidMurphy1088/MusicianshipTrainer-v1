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

class ContentSectionData {
    var type:String
    var data:[String]
    var row:Int
    init(row:Int, type:String, data:[String]) {
        self.row = row
        self.type = type
        self.data = data
    }
}

class ContentSection: Identifiable {
    let id = UUID()
    var parent:ContentSection?
    var name: String
    var type:String
    let contentSectionData:ContentSectionData
    var subSections:[ContentSection] = []
    var isActive:Bool
    var level:Int
    var index:Int
    
    init(parent:ContentSection?, name:String, type:String, data:ContentSectionData? = nil, isActive:Bool = true) {
        self.parent = parent
        self.name = name
        self.isActive = isActive
        self.type = type
        if data == nil {
            self.contentSectionData = ContentSectionData(row: 0, type: "", data: [])
        }
        else {
            self.contentSectionData = data!
        }
        var par = parent
        var level = 0
        var path = name
        while par != nil {
            level += 1
            path = par!.name+"."+path
            par = par!.parent
        }
        self.level = level
        //self.loadedDictionaryKey = loadedDictionaryKey
        //self.loadedRow = loadedRow
        self.index = 0
    }
    
    func debug() {
        let spacer = String(repeating: " ", count: 4 * (level))
        print(spacer, "--->", "path:[\(self.getPath())]", "\tname:", self.name, "\ttype:[\(self.type)]")
//        let sorted:[ContentSection] = subSections.sorted { (c1, c2) -> Bool in
//            //return c1.loadedRow < c2.loadedRow
//            return c1.name < c2.name
//        }
        for s in self.subSections {
            s.debug()
        }
    }
    
    func isQuestionType() -> Bool {
        if type.first == "_" {
            return false
        }
        let components = self.type.split(separator: "_")
        if components.count != 2 {
            return false
        }
        if let n = Int(components[1]) {
            return n >= 0 && n <= 5
        }
        else {
            return false
        }
    }
    
    func getQuestionCount() -> Int {
        var c = 0
        for section in self.subSections {
            if section.isQuestionType() {
                c += 1
            }
        }
        return c
    }
    
    func getNavigableChildSections() -> [ContentSection] {
        var sections:[ContentSection] = []
        for section in self.subSections {
            if section.subSections.count > 0 {
                var sectionHasQuestions = false
                for s in section.subSections {
                    if s.isQuestionType() {
                        sectionHasQuestions = true
                        break
                    }
                }
                if sectionHasQuestions {
                    sections.append(section)
                }
            }
            else {
                if section.isQuestionType() {
                    sections.append(section)
                }
            }
        }

        return sections
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
        if self.type == type {
            return self
        }
        else {
            for child in self.subSections {
                var found = child.getChildSectionByType(type: type)
                if let found = found {
                    return found
                }
            }
        }
        return nil
    }
    
    func isExamMode() -> Bool {
        let path:String = self.getPath()
        let exam = path.uppercased().contains("EXAM MODE")
        return exam
    }
    
    func parseData(warnNotFound:Bool=true) -> [Any]! {
        let data = self.contentSectionData.data
        guard data != nil else {
            if warnNotFound {
                Logger.logger.reportError(self, "No data for content section:[\(self.getPath())]")
            }
            return nil
        }
        //let tuples:[String] = data!
        let tuples:[String] = data
        
        if type == "I" {
            return [tuples[0]]
        }

        var result:[Any] = []
        
        for i in 0..<tuples.count {
            var tuple = tuples[i].replacingOccurrences(of: "(", with: "")
            tuple = tuple.replacingOccurrences(of: ")", with: "")
            let parts = tuple.components(separatedBy: ",")
            
            //Fixed
            
            if i == 0 {
                result.append(KeySignature(type: .sharp, count: parts[0] == "C" ? 0 : 1))
                continue
            }
            if i == 1 {
                if parts.count == 1 {
                    let ts = TimeSignature(top: 4, bottom: 4)
                    ts.isCommonTime = true
                    result.append(ts)
                    continue
                }

                if parts.count == 2 {
                    result.append(TimeSignature(top: Int(parts[0]) ?? 0, bottom: Int(parts[1]) ?? 0))
                    continue
                }
                Logger.logger.reportError(self, "Unknown time signature tuple at \(i) :  \(self.getTitle()) \(tuple)")
                continue
            }
            if i == 2 {
                if parts.count == 1 {
                    if let lines = Int(parts[0]) {
                        result.append(StaffCharacteristics(lines: lines))
                        continue
                    }
                }
                Logger.logger.reportError(self, "Unknown staff line tuple at \(i) :  \(self.getTitle()) tuple:[\(tuple)]")
                continue
            }
            
            // Repeating
            
            if parts.count == 1  {
                if parts[0] == "B" {
                    result.append(BarLine())
                }
                continue
            }
            
            if parts.count == 2 || parts.count == 3  {
                let notePitch:Int? = Int(parts[0])
                if let notePitch = notePitch {
                    let value = Double(parts[1]) ?? 1
                    var accidental:Int?
                    if parts.count == 3 {
                        if let acc = Int(parts[2]) {
                            accidental = acc
                        }
                    }
                    result.append(Note(num: notePitch, value: value, accidental: accidental))
                }
                continue
            }
            Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(self.getTitle()) \(tuple)")
        }
        return result
    }

}

class Syllabus {
    static public let shared = Syllabus()
}
