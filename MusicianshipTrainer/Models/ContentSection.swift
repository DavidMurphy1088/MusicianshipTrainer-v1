import Foundation
import AVFoundation
import Combine

enum ExamStatus {
    case notInExam
    case inExam
    case inExamReview
}

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

class ContentSection: ObservableObject, Identifiable { //Codable,
    @Published var selectedIndex:Int? //The row to go into
    @Published var postitionToIndex:Int? //The row to postion to
    
    var id = UUID()
    var parent:ContentSection?
    var name: String
    var type:String
    let contentSectionData:ContentSectionData
    var subSections:[ContentSection] = []
    var isActive:Bool
    var level:Int
    var storedAnswer:Answer?
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
    }
    
    func setSelected(_ i:Int) {
        DispatchQueue.main.async {
            ///Force the selected Index to trigger a change event
            self.selectedIndex = nil
            DispatchQueue.global(qos: .background).async {
                sleep(1)
                DispatchQueue.main.async {
                    self.postitionToIndex = i
                    DispatchQueue.global(qos: .background).async {
                        sleep(1)
                        DispatchQueue.main.async {
                            self.selectedIndex = i
                        }
                    }
                }
            }
        }
}
    
    func getGrade() -> Int {
        var grade:Int = 1
        let paths = getPathAsArray()
        for path in paths {
            if path.starts(with: "Grade ") {
                let p = path.split(separator: " ")
                if p.count == 2 {
                    if let gradeInt = Int(p[1]) {
                        grade = gradeInt
                        break
                    }
                }
            }
        }
        return grade
    }

    func storeAnswer(answer: Answer) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(answer)
            let jsonString = String(data: jsonData, encoding: .utf8)
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
                self.storedAnswer = answer
            }
            catch {
                //Logger.logger.reportError(self, "Failed to parse JSON \(error)")
            }
        }
        else {
            Logger.logger.reportError(self, "Failed answer read, no document URL")
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
    
    ///Search all parents with a true test supplied by the caller
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
        
    func getTitle() -> String {
        if let path = Bundle.main.path(forResource: "NameToTitleMap", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            if let stringValue = dict[self.name] as? String {
                return stringValue
            }
        }
        
        /// Remove leading zero in example number
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
            if section.name.count > 0 {
                path.append(section.name)
            }
            if let parent = section.parent {
                section = parent
            }
            else {
                break
            }
        }
        return path.reversed()
    }
    
    func getExamTakingStatus() -> ExamStatus {
        guard let parent = parent else {
            return .notInExam
        }
        if parent.isExamTypeContentSection() {
            if storedAnswer == nil {
                return .inExam
            }
            else {
                return .inExamReview
            }
        }
        else {
            return .notInExam
        }
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
            if section.storedAnswer != nil {
                return false
            }
        }
        return true
    }
    
    func getScore(staffCount:Int, onlyRhythm:Bool, warnNotFound:Bool=true) -> Score {
        return parseData(staffCount: staffCount, onlyRhythm: onlyRhythm)
    }
    
    func parseData(staffCount:Int, onlyRhythm:Bool, warnNotFound:Bool=true) -> Score {
        let data = self.contentSectionData.data
        var key:Key?
        var timeSignature:TimeSignature?
        var score:Score?
        let defaultScore = Score(key: Key(type: .major, keySig: KeySignature(type: .sharp, keyName: "")), timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 1)

        let tuples:[String] = data
        
        for i in 0..<tuples.count {
            let trimmedTuple = tuples[i].trimmingCharacters(in: .whitespacesAndNewlines)
            var tuple = trimmedTuple.replacingOccurrences(of: "(", with: "")
            tuple = tuple.replacingOccurrences(of: ")", with: "")
            let parts = tuple.components(separatedBy: ",")

            if i == 0 {
                let keySignature = KeySignature(type: .sharp, keyName: parts[0])
                key = Key(type: .major, keySig: keySignature)
                continue
            }
            if i == 1 {
                if parts.count == 1 {
                    let ts = TimeSignature(top: 4, bottom: 4)
                    ts.isCommonTime = true
                    timeSignature = ts
                    continue
                }

                if parts.count == 2 {
                    let ts = TimeSignature(top: Int(parts[0]) ?? 0, bottom: Int(parts[1]) ?? 0)
                    //result.append()
                    timeSignature = ts
                    continue
                }
                Logger.logger.reportError(self, "Unknown time signature tuple at \(i) :  \(self.getTitle()) \(tuple)")
                continue
            }
            
            if score == nil {
                if let key = key {
                    if let timeSignature = timeSignature {
                        score = Score(key: key, timeSignature: timeSignature, linesPerStaff: 5)
                        for i in 0..<staffCount {
                            let staff = Staff(score: score!, type: .treble, staffNum: i, linesInStaff: onlyRhythm ? 1 : 5)
                            score!.setStaff(num: i, staff: staff)
                        }
                    }
                }
            }
            
            if parts.count == 1  {
                if parts[0] == "B" {
                    if let score = score {
                        score.addBarLine()
                    }
                }
                if parts[0] == "T" {
                    if let score = score {
                        score.addTie()
                    }
                }
                continue
            }

            if parts.count == 2  {
                if parts[0] == "R" {
                    if let score = score {
                        let timeSlice = score.createTimeSlice()
                        let restValue = Double(parts[1]) ?? 1
                        let rest = Rest(timeSlice: timeSlice, value: restValue, staffNum: 0)
                        timeSlice.addRest(rest: rest)
                        continue
                    }
                }
            }

            if parts.count == 2 || parts.count == 3 || parts.count == 4 {
                var notePitch:Int?
                var value:Double?
                var accidental:Int?
                var triad:String?

                for i in 0..<parts.count {
                    if i == 0 {
                        notePitch = Int(parts[i])
                        continue
                    }
                    if i == 1 {
                        value = Double(parts[i]) ?? 1
                        continue
                    }
                    accidental = Int(parts[i])
                    if accidental == nil {
                        if ["V","I"].contains(parts[i]) {
                            triad = parts[i]
                        }
                    }
                }
                if let notePitch = notePitch {
                    if let value = value {
                        if let score = score {
                            let timeSlice = score.createTimeSlice()
                            let note = Note(timeSlice: timeSlice, num: onlyRhythm ? 71 : notePitch, value: value, staffNum: 0, accidental: accidental)
                            note.staffNum = 0
                            note.isOnlyRhythmNote = onlyRhythm
                            timeSlice.addNote(n: note)
                            if let triad = triad {
                                addTriad(score: score, timeSlice: timeSlice, note: note, triad: triad, value: note.getValue())
                            }
                        }
                    }
                }
                continue
            }
            Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(self.getTitle()) \(tuple)")
        }
        if let score = score {
            //score.debugScorex("ContentSection Parse", withBeam: false)
            return score
        }
        else {
            return defaultScore
        }
    }
        
    func addTriad(score:Score, timeSlice:TimeSlice, note:Note, triad:String, value:Double) {
        let bstaff = Staff(score: score, type: .bass, staffNum: 1, linesInStaff: 5)
        score.setStaff(num: 1, staff: bstaff)
        let key = score.key
        
        var pitch = key.firstScaleNote()
        if triad == "V" {
            pitch += 7
        }
        if pitch < 41 {
            pitch += 12
        }
        else {
            if pitch > 52 {
                pitch -= 12
            }
        }
        let root = Note(timeSlice:timeSlice, num: pitch, staffNum: 0)
        //timeSlice.setTags(high: TagHigh(content:root.getNoteName(), popup: nil), low: triad)
        timeSlice.setTags(high: TagHigh(content:Note.getNoteName(midiNum: root.midiNumber), popup: nil), low: triad)

        for i in [0,4,7] {
            timeSlice.addNote(n: Note(timeSlice: timeSlice, num: pitch + i, value:value, staffNum: 1))
        }
    }
    
    func playExamInstructions(withDelay:Bool, onLoaded: @escaping (_ status:RequestStatus) -> Void, onNarrated: @escaping () -> Void) {
        let filename = "Instructions.m4a"
        var pathSegments = getPathAsArray()
        //remove the exam title from the path
        pathSegments.remove(at: 2)
        let googleAPI = GoogleAPI.shared
        var dataRecevied = false
        googleAPI.getAudioDataByFileName(pathSegments: pathSegments, fileName: filename, reportError: true) {status, fromCache, data in
            if status == .failed {
                onLoaded(.failed)
            }
            else {
                if !dataRecevied {
                    dataRecevied = true
                    onLoaded(.success)
                    DispatchQueue.global(qos: .background).async {
                        if data != nil {
                            if fromCache {
                                ///Dont start speaking at the instant the view is loaded
//                                if withDelay {
//                                    sleep(1)
//                                }
                            }
                        }
                        AudioRecorder.shared.playFromData(data: data!, onDone: onNarrated)
                    }
                }
            }
        }
    }

}

