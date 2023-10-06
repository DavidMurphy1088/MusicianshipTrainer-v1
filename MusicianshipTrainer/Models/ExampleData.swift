import Foundation

class ExampleData : ObservableObject {
    static var sharedExampleData = ExampleData()
    var logger = Logger.logger
    //private var loadedDataDictionary:[String: ContentSectionData ] = [:]
    private let googleAPI = GoogleAPI.shared
    
    @Published var dataStatus:RequestStatus = .waiting

    private init() {
        self.dataStatus = .waiting
        loadData()
    }
    
    func loadData() {
        MusicianshipTrainerApp.root.subSections = []
        googleAPI.getContentSheet(sheetName: "ContentSheetID") { status, data in
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
            
            let melody = Melody(halfSteps: halfSteps, name: name)
            for i in 3..<rowCells.count {
                let parts = rowCells[i].components(separatedBy: ",")
                if parts.count < 2 {
                    continue
                }
                guard let pitch = Int(parts[0]) else {
                    continue
                }
                guard let value = Double(parts[1]) else {
                    continue
                }
                melody.notes.append(Note(timeSlice: nil, num:pitch, value:Double(value), staffNum: 0))
            }
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
                                contentSection.loadAnswer()
                            }
                        }
                        //print("\nRow:", rowNum, "Index:", cellIndex, rowCells)
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

