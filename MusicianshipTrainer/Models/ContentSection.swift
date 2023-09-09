import Foundation
import AVFoundation
import Combine

class QuestionStatus: Codable, ObservableObject {
    //@Published
    var status:Int = 0
    init(_ i:Int) {
        self.status = i
    }
    func setStatus(_ i:Int) {
        DispatchQueue.main.async {
            self.status = i
        }
    }
}

class ContentSectionData: Codable {
    var type:String
    var data:[String]
    var row:Int
    init(row:Int, type:String, data:[String]) {
        self.row = row
        self.type = type
        self.data = data
    }
}

class ContentSection: Codable, Identifiable {
    var id = UUID()
    var parent:ContentSection?
    var name: String
    var type:String
    let contentSectionData:ContentSectionData
    var subSections:[ContentSection] = []
    var isActive:Bool
    var level:Int
    var index:Int
    var answer111:Answer?
    var questionStatus = QuestionStatus(0)
    
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
        self.index = 0
    }
    
    func storeAnswer(answer: Answer) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(answer)
            let jsonString = String(data: jsonData, encoding: .utf8)
            //let fileManager =
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            if let documentsURL = documentsURL {
                let fileName = self.getPath() + ".txt"
                let fileURL = documentsURL.appendingPathComponent(fileName)
                let content = jsonString // "This is an example."
                if let content = content {
                    let data = content.data(using: .utf8)
                    try data?.write(to: fileURL, options: .atomic)
                }
                
            } else {
                Logger.logger.reportError(self, "Failed answer save, no document URL")
            }
        } catch {
            Logger.logger.reportError(self, "Failed answer save \(error)")
        }
    }
    
    func loadAnswer() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let decoder = JSONDecoder()
        if let documentsURL = documentsURL {
            let fileName = self.getPath() + ".txt"
            let fileURL = documentsURL.appendingPathComponent(fileName)
            do {
                let data = try Data(contentsOf: fileURL)
                let answer = try decoder.decode(Answer.self, from: data)
                self.answer111 = answer
            }
            catch {
                //print("Failed to read answer JSON: \(error)")
            }
        }
        else {
            Logger.logger.reportError(self, "Failed answer read, no document URL")
            print("Failed to read answer")
        }
    }
    
    func isExamTypeContentSection() -> Bool {
        if type == "Exam" {
            return true
        }
        return false
    }

    func hasExamModeChildren() -> Bool {
        for s in self.subSections {
            if s.isExamTypeContentSection() {
                return true
            }
        }
        return false
    }
    
    func getChildOfType(_ type:String) -> ContentSection? {
        for s in self.subSections {
            if s.type == type {
                return s
            }
        }
        return nil
    }

    ///Recursivly search all children with a true test supplied by the caller
    func deepSearch(testCondition:(_ section:ContentSection)->Bool) -> Bool {
        if testCondition(self) {
            return true
        }
        for section in self.subSections {
            if testCondition(section) {
                return true
            }
            if section.deepSearch(testCondition: testCondition) {
                return true
            }
        }
        return false
    }
    
    ///Recursivly search all children with a true test supplied by the caller
    func parentSearch(testCondition:(_ section:ContentSection)->Bool) -> Bool {
        if testCondition(self) {
            return true
        }
        if let parent = self.parent  {
            if testCondition(parent) {
                return true
            }
            if parent.parentSearch(testCondition: testCondition) {
                return true
            }
        }
        return false
    }

    func parentWithInstructions() -> ContentSection? {
        var section = self
        while section != nil {
            if section.getChildOfType("Ins") != nil {
                return section
            }
            if let parent = section.parent {
                section = parent
            }
            else {
                break
            }
        }
        return nil
    }
    
    func debug() {
        //let spacer = String(repeating: " ", count: 4 * (level))
        //print(spacer, "--->", "path:[\(self.getPath())]", "\tname:", self.name, "\ttype:[\(self.type)]")
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
        var navSections:[ContentSection] = []
        for section in self.subSections {
            if section.deepSearch(testCondition: {
                section in
                return !(["Ins", "T&T"].contains(section.type))
                //return section.isQuestionType()
            }
            )
            {
                navSections.append(section)
            }
        }
        return navSections
    }
    
//    func getNavigableChildSectionsOld() -> [ContentSection] {
//        var sections:[ContentSection] = []
//        for section in self.subSections {
//            if section.subSections.count > 0 {
//                section.getChildOfType(<#T##type: String##String#>)
//                var sectionHasQuestions = false
//                for s in section.subSections {
//                    if s.isQuestionType() {
//                        sectionHasQuestions = true
//                        break
//                    }
//                }
//                if sectionHasQuestions {
//                    sections.append(section)
//                }
//            }
//            else {
//                if section.isQuestionType() {
//                    sections.append(section)
//                }
//            }
//        }
//
//        return sections
//    }
    
    func getTitle() -> String {
        if let path = Bundle.main.path(forResource: "NameToTitleMap", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            if let stringValue = dict[self.name] as? String {
                return stringValue
            }
        }
        
        // remove leading zero in example number
        if name.range(of: "example", options: .caseInsensitive) != nil {
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
    
    func getPathAsArray() -> [String] {
        var path:[String] = []
        var section = self
        while true {
            path.append(section.name)
            if let parent = section.parent {
                section = parent
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
        //print("getChildSectionByType", name, type)
        if self.type == type {
            return self
        }
        else {
            for child in self.subSections {
                //not beyond next level...
                //var found = child.getChildSectionByType(type: type)
                if child.type == type {
                    return child
                }
            }
        }
        return nil
    }
    
    func hasNoAnswers() -> Bool {
        for section in self.subSections {
            if section.answer111 != nil {
                return false
            }
        }
        return true
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
                var keySigCount = 0
                result.append(KeySignature(type: .sharp, keyName: parts[0]))
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
            
            if parts.count == 2  {
                if parts[0] == "R" {
                    let restValue = Double(parts[1]) ?? 1
                    result.append(Rest(value: restValue, staffNum: 0))
                    continue
                }
                
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
                    
                    result.append(Note(num: notePitch, value: value, staffNum: 0, accidental: accidental))
                }
                continue
            }
            Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(self.getTitle()) \(tuple)")
        }
        return result
    }

}

