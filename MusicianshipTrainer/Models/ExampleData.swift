import Foundation

class ExampleData : ObservableObject {
    static var sharedExampleData = ExampleData()
    var logger = Logger.logger
    private let googleAPI = GoogleAPI.shared
    
    @Published var dataStatus:RequestStatus = .waiting

    private init() {
        self.dataStatus = .waiting
        loadData()
    }
    
    func loadData() {
        MusicianshipTrainerApp.root.subSections = []
        let sheetName = Settings.shared.useTestData ? "ContentSheetID_TEST" : "ContentSheetID"
        googleAPI.getContentSheet(sheetName: sheetName) { status, data in
            if status == .success {
                if let data = data {
                    struct JSONSheet: Codable {
                        let range: String
                        let values:[[String]]
                    }
                    do {
                        let jsonData = try JSONDecoder().decode(JSONSheet.self, from: data)
                        let sheetRows = jsonData.values
                        self.loadSheetData(sheetRows: sheetRows)
                        Logger.logger.log(self, "Loaded \(sheetRows.count) sheet rows")
                        MusicianshipTrainerApp.root.debug()
                        self.setDataReady(way: status)
                    }
                    catch {
                        self.logger.log(self, "Cannot parse JSON content")
                    }
                }
                else {
                    self.setDataReady(way: .failed)
                    self.logger.log(self, "No content data")
                }
            }
            else {
                self.setDataReady(way: status)
            }
        }
        
        googleAPI.getContentSheet(sheetName: "MelodiesSheetID") { status, data in
            if status == .success {
                if let data = data {
                    struct JSONSheet: Codable {
                        let range: String
                        let values:[[String]]
                    }
                    do {
                        let jsonData = try JSONDecoder().decode(JSONSheet.self, from: data)
                        let sheetRows = jsonData.values
                        self.loadMelodies(sheetRows: sheetRows)
                    }
                    catch {
                        self.logger.log(self, "Cannot parse melody content")
                    }
                }
                else {
                    self.setDataReady(way: .failed)
                    self.logger.log(self, "No melody data")
                }
            }
            else {
                self.setDataReady(way: status)
            }

        }
    }
    
    func loadMelodies(sheetRows:[[String]]) {
        for rowCells in sheetRows {
            if rowCells.count < 4 {
                continue
            }

            if rowCells[0].hasPrefix("//")  {
                continue
            }
            guard let halfSteps = Int(rowCells[1]) else {
                continue
            }
            let name = rowCells[2]
            if name.count == 0 {
                continue
            }
            let score = Score(key: Key(type: .major, keySig: KeySignature(type: .sharp, keyName: "")), timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 1)
            score.createStaff(num: 0, staff: Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5))
            let melody = Melody(halfSteps: halfSteps, name: name)
            for i in 3..<rowCells.count {
                let parts = rowCells[i].components(separatedBy: ",")
                if parts.count < 2 {
                    continue
                }
                let timeSlice = TimeSlice(score: score)
                guard let value = Double(parts[1]) else {
                    continue
                }
                if parts[0] == "R" {
                    let rest = Rest(timeSlice: timeSlice, value: value, staffNum: 0)
                    timeSlice.addRest(rest: rest)
                }
                else {
                    guard let pitch = Int(parts[0]) else {
                        continue
                    }
                    let note = Note(timeSlice: timeSlice, num:pitch, value:Double(value), staffNum: 0)
                    if parts.count == 3 {
                        let accidental = Int(parts[2])
                        if [0,1,2].contains(accidental) {
                            note.accidental = accidental
                        }
                    }
                    timeSlice.addNote(n: note)
                }
                melody.timeSlices.append(timeSlice)
            }
            melody.data = Array(rowCells.dropFirst(3))
            Melodies.shared.addMelody(melody: melody)
        }
    }
    
    func loadSheetData(sheetRows:[[String]]) {
        var rowNum = 0
        let keyStart = 2
        let keyLength = 4
        let typeIndex = 7
        let dataStart = typeIndex + 2
        var contentSectionCount = 0
        var lastContentSectionDepth:Int?
        
        var levelContents:[ContentSection?] = Array(repeating: nil, count: keyLength)
        
        for rowCells in sheetRows {

            rowNum += 1
            if rowCells.count > 0 {
                if rowCells[0].hasPrefix("//")  {
                    continue
                }
            }
            let contentType = rowCells.count < typeIndex ? "" : rowCells[typeIndex].trimmingCharacters(in: .whitespaces)
            
            var rowHasAKey = false
            for cellIndex in keyStart..<keyStart + keyLength {
                if cellIndex < rowCells.count {
                    let keyData = rowCells[cellIndex].trimmingCharacters(in: .whitespaces)
                    if !keyData.isEmpty {
                        rowHasAKey = true
                        break
                    }
                }
            }
                            
            for cellIndex in keyStart..<keyStart + keyLength {
                var keyData:String? = nil
                if cellIndex < rowCells.count {
                    keyData = rowCells[cellIndex].trimmingCharacters(in: .whitespaces)
                }
                //a new section for type with no section name
                if let lastContentSectionDepth = lastContentSectionDepth {
                    if cellIndex > lastContentSectionDepth {
                        if !rowHasAKey {
                            if !contentType.isEmpty {
                                keyData = "_" + contentType + "_"
                            }
                        }
                    }
                }

                if let keyData = keyData {
                    if !keyData.isEmpty {
                        let keyLevel = cellIndex - keyStart
                        let parent = keyLevel == 0 ? MusicianshipTrainerApp.root : levelContents[keyLevel-1]
                        let contentData:[String]
                        if rowCells.count > dataStart {
                            contentData = Array(rowCells[dataStart...])
                        }
                        else {
                            contentData = []
                        }
                        let name = keyData.trimmingCharacters(in: .whitespacesAndNewlines)
                        let contentSection = ContentSection(
                            parent: parent,
                            name: name,
                            type: contentType.trimmingCharacters(in: .whitespacesAndNewlines),
                            data: ContentSectionData(row: rowNum,
                                                     type: contentType.trimmingCharacters(in: .whitespacesAndNewlines),
                                                     data: contentData))
                        contentSectionCount += 1
                        levelContents[keyLevel] = contentSection
                        parent?.subSections.append(contentSection)
                        if rowHasAKey {
                            lastContentSectionDepth = cellIndex
                        }
                        if let parent = contentSection.parent {
                            if parent.isExamTypeContentSection() {
                                contentSection.loadAnswerFromFile()
                            }
                            else {
                                if UIGlobals.companionAppActive {
                                    contentSection.loadAnswerFromFile()
                                }
                            }
                        }
                        //MusicianshipTrainerApp.root.debug()
                    }
                }
            }
        }
    }

    //load data from Google Drive Sheet

    func setDataReady(way:RequestStatus) {
        DispatchQueue.main.async {
            self.dataStatus = way
        }
    }
    
}

