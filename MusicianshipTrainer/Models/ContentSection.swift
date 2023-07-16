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
    
    init(parent:ContentSection?, name:String, type:String, instructions:String?, isActive:Bool = true) {
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
//        if let title = title {
//            self.title = title
//        }
//        else {
//            self.title = name
//        }
        //let exampleData = ExampleData.shared
//        for key in exampleData.data.keys.sorted() {
//            let data = "" //exampleData.data[key]
//            let keyLevels = key.filter { $0 == "." }.count  //NZMEB is level 1 with parent the root
//            //print ("CSection-->lvl:", level, "parent:", parent?.name, "key:", key, keyLevels)
//            print (String(repeating: " ", count: 3 * keyLevels), " create content section-->path:\(path) key:\(key) level:\(level)", key)
//
//            if path == key {
//                if level < 2 {
//                    //print ("  ADD:", String(repeating: " ", count: 3 * keyLevels), " create content section-->path:\(path) key:\(key) level:\(level)", key)
//                    subSections.append(ContentSection(parent: self, type: SectionType.grade, name: key))
//                }
//            }
//        }
//          App will be licensed by grade now so dont show all grades
//        if level == 0 {
//            subSections.append(ContentSection(parent: self, type: SectionType.grade, name: "Pre Preliminary"))
//            subSections.append(ContentSection(parent: self, type: SectionType.grade, name: "Preliminary"))
//            subSections.append(ContentSection(parent: self, type: SectionType.grade, name: "Grade 1", isActive: true))
//            for i in 2..<9 {
//                subSections.append(ContentSection(parent: self, type: SectionType.grade, name: "Grade \(i)"))
//            }
//        }
        
//        if level == 0 {
//            subSections.append(ContentSection(parent: self, type: SectionType.testType, name:"Intervals Visual", title:"Recognising Visual Intervals"))
//            subSections.append(ContentSection(parent: self, type: SectionType.testType, name:"Clapping", title:"Tapping At Sight"))
//            subSections.append(ContentSection(parent: self, type: SectionType.testType, name:"Playing", title: "Playing At Sight"))
//            subSections.append(ContentSection(parent: self, type: SectionType.testType, name:"Intervals Aural", title:"Recognising Aural Intervals"))
//            subSections.append(ContentSection(parent: self, type: SectionType.testType, name:"Echo Clap"))
//        }
//        let exampleData = ExampleData.shared
//        if let parent = parent {
//            let key = "\(parent.name).\(name).Instructions"
//            if exampleData.data.keys.contains(key) {
//                self.instructions = exampleData.data[key]![0]
//            }
//        }
//
//        if level == 1 {
//            for i in 1...100 {
//                addExample(exampleNum: i)
//            }
//        }
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
