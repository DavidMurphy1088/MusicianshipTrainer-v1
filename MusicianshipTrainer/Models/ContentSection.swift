import Foundation
import AVFoundation

class ContentSection: Identifiable {
    let id = UUID()
    var name: String = ""
    var title: String
    var subSections:[ContentSection] = []
    var sectionType:SectionType
    var parent:ContentSection?
    var isActive:Bool
    var level:Int
    var instructions:String?
    
    enum SectionType {
        case none
        case grade
        case testType
        case example
    }
    
    init(parent:ContentSection?, type:SectionType, name:String, title:String? = nil, isActive:Bool = true) {
        self.parent = parent
        self.sectionType = type
        self.name = name        
        self.isActive = isActive
        var par = parent
        var level = 0
        var path = name
        while par != nil {
            level += 1
            path = par!.name+"."+path
            par = par!.parent
        }
        self.level = level
        if let title = title {
            self.title = title
        }
        else {
            self.title = name
        }
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
    
    func getPathName() -> String {
        var path = ""
        var section = self
        while true {
            path = section.name + path
            if let parent = section.parent {
                section = parent
                path = "." + path
            }
            else {
                break
            }
        }
        return path
    }
    
    func getPathTitle() -> String {
        var path = ""
        var section = self
        while true {
            path = section.title + path
            if let parent = section.parent {
                section = parent
                path = "." + path
            }
            else {
                break
            }
        }
        return path
    }

    //Add an example number if the data for it exists
//    func addExample(exampleNum:Int) {
//        let exampleName = "Example \(exampleNum)"
//        var key = self.name+"."+exampleName
//        if parent != nil {
//            //key = "Musicianship."+parent!.name+"."+key//TODO fix this...
//            key = parent!.name+"."+key
//        }
//        let exampleData = ExampleData.shared.getData(key: key, warnNotFound: false)
//        //let exampleData = ExampleData.shared.get(contentSection: self)
//        if exampleData == nil {
//            return
//        }
//        subSections.append(ContentSection(parent: self, type: SectionType.example, name:exampleName, isActive: true))
//    }
}

class Syllabus {
    static public let shared = Syllabus()
}
