import Foundation

class ExampleData : ObservableObject {
    static var shared1 = ExampleData()
    var logger = Logger.logger
    private var loadedDataDictionary:[String: ContentSectionData ] = [:]
    private let googleAPI = GoogleAPI.shared
    
    @Published var dataStatus:RequestStatus = .waiting

    private init() {
        self.dataStatus = .waiting
        loadData()
    }
    
    func loadData() {
        loadedDataDictionary = [:]
        googleAPI.getExampleSheet() { status, data in
            if status == .success {
                if let data = data {
                    //let val = data.values
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
                        self.logger.log(self, "loaded \(self.loadedDataDictionary.count) example rows")
                    }
                    catch {
                        self.logger.log(self, "failed load \(self.loadedDataDictionary.count) example rows")
                    }
                }
                else {
                    self.setDataReady(way: .failed)
                    self.logger.log(self, "failed load \(self.loadedDataDictionary.count) example rows")
                }
            }
            else {
                self.setDataReady(way: status)
            }
        }
    }
    
    //load data from Google Drive Sheet
    func loadSheetData(sheetRows:[[String]]) {

        ///set according to the format of the examples Sheet
        let keyStart = 1
        let keyEnd = 5
        var keyPathParts:[String] = Array(repeating: "", count: keyEnd - keyStart + 1)

        let typeColumnStart = 7
        let dataOffsetStart = 9   //start of data
        var rowNum = 0
        
        for rowCells in sheetRows {
            rowNum += 1
            if rowCells.count == 0 {
                continue
            }

            if rowCells[0].hasPrefix("//")  {
                continue
            }

            var rowData:[String] = []
            var rowType:String = ""
            var rowIsBlank = true
            var rowHasData = false

            for i in 0..<rowCells.count {
                if i<keyStart {
                    continue
                }
                
                let cell = rowCells[i]
                let cellData = cell.trimmingCharacters(in: .whitespaces)
                
                if !cellData.isEmpty {
                    rowIsBlank = false
                }

                if i >= keyStart && i <= keyEnd {
                    if !cellData.isEmpty {
                        //periods in data confuse the key structure navigation :(
                        let keyData = cellData.replacingOccurrences(of: ".", with: "_")
                        keyPathParts[i - keyStart] = keyData
                        //clear the key to the right
                        for j in i - keyStart+1..<keyPathParts.count {
                            keyPathParts[j] = ""
                        }
                    }
                }
                
                if i == typeColumnStart {
                    if rowNum == 234 || rowNum == 235 {
                        print("")
                    }

                    rowType = cell
                }

                if i >= dataOffsetStart {
                    //let cellData = cell
                    rowData.append("\(cell)")
                    if !cellData.isEmpty {
                        rowHasData = true
                    }
                }
            }
            if rowIsBlank {
                continue
            }
            
            if rowHasData {
                if rowType.isEmpty {
                    Logger.logger.reportError(self, "row \(rowNum) has no type")
                    return
                }
            }
            
            //remove unlicensed keys
            var key:String? = nil
            for i in 0..<keyPathParts.count {
                let path = keyPathParts[i].trimmingCharacters(in: .whitespaces)
                if i==0 && path != "NZMEB" {
                    key = nil
                    break
                }
                if i==1 && path != "Grade 1" {
                    key = nil
                    break
                }
                //remove unlicensed content
                if i >= 2 {
                    if !path.isEmpty {
                        if key == nil {
                            key = ""
                        }
                        else {
                            key! += "."
                        }
                        key! += path
                    }
                }
            }
            
            if var key = key {
                //hack - unless types for instrucion and T&T have unqiue keys the dictionary can only store one of them
                if !rowType.isEmpty && !rowType.hasPrefix("Type_") {
                    key += ".__" + rowType + "__"
                }

                self.loadedDataDictionary[key] = ContentSectionData(row: rowNum, type: rowType, data: rowData)
            }
        }
//        for k in self.loadedDataDictionary.keys.sorted() {
//            print("loadSheetData::", k, "\ttype:[\(loadedDataDictionary[k]?.type)]")
//        }
        loadContentSections()
    }
    
    func arrayToKeyStr(_ parts:[String]) -> String {
        var str = ""
        for p in parts {
            if !str.isEmpty {
                str += "."
            }
            str += p
        }
        return str
    }
    
    ///Create the nested content sections with their child sections
    func loadContentSections() {
        var parents:[String : ContentSection] = [:]
        
        for loadedDictionaryKey in self.loadedDataDictionary.keys.sorted() {

            let allKeyParts = loadedDictionaryKey.split(separator: ".")
            var keyParts:[String] = []
            for i in 0..<allKeyParts.count {
                let part = String(allKeyParts[i]).trimmingCharacters(in: .whitespaces)
                keyParts.append(part)
            }
            if loadedDictionaryKey.contains("David_Test_Exam_1") {
                print("")
            }
            for i in 0..<keyParts.count {
                //A blank key part designates the end of the content structure
//                if keyParts[i] == "" {
//                    break
//                }
                //Find the key's parent
                var parentSection:ContentSection
                if i == 0 {
                    parentSection = MusicianshipTrainerApp.root
                }
                else {
                    let parentKey = arrayToKeyStr(Array(keyParts.prefix(i)))
                    if parents[parentKey] == nil {
                        Logger.logger.reportError(self, "No parent for key:\(parentKey)")
                        return
                    }
                    parentSection = parents[parentKey]!
                }
                var hasSubsection = false
                for subSection in parentSection.subSections {
                    if subSection.name == keyParts[i] {
                        hasSubsection = true
                        break
                    }
                }
                
                //The the parent does not have this subsection, add it
                if !hasSubsection {
                    let loadedData = self.loadedDataDictionary[loadedDictionaryKey]
                    let sectionName = keyParts[i]
                    let contentSection = ContentSection(parent: parentSection,
                                                        name: sectionName,
                                                        type: loadedData!.type,
                                                        data: loadedData!
                                                        //loadedDictionaryKey: loadedDictionaryKey,
                                                        //loadedRow: loadedData!.row
                    )
                    parentSection.subSections.append(contentSection)
                    //present the sections in the order in which they were loaded from the Sheet (not alpahbetically...)
                    let sorted:[ContentSection] = parentSection.subSections.sorted { (c1, c2) -> Bool in
                        //return c1.loadedRow < c2.loadedRow
                        return c1.contentSectionData.row < c2.contentSectionData.row
                    }
                    var index = 0
                    for section in sorted {
                        section.index = index
                        index += 1
                    }
                    parentSection.subSections = sorted
                    
                    let dictKey = contentSection.getPath()
                    parents[dictKey] = contentSection
                    
                    let keyLevel = dictKey.components(separatedBy: ".").count
                    //Comment maybe but dont delete.
//                    print("\n", String(repeating: " ", count: 4 * (keyLevel-1)),
//                          "ContentSection--> key:[\(loadedDictionaryKey)] \tname:[\(contentSection.name)]  \trow:\(loadedData?.row) type:\(loadedData?.type) Row:\(loadedData?.row) \tdata:\(loadedData?.data)")

                }
            }
        }
    }

    func setDataReady(way:RequestStatus) {
        DispatchQueue.main.async {
            self.dataStatus = way
        }
    }
    
    func getTypeOld(key:String) -> String? {
        let data = self.loadedDataDictionary[key]
        guard data != nil else {
            Logger.logger.reportError(self, "No type for key:[\(key)]")
            return nil
        }
        return data!.type
    }
    
    func getFirstColOld(key:String) -> String? {
        let data = self.loadedDataDictionary[key]
        guard data != nil else {
            Logger.logger.reportError(self, "No first col for key:[\(key)]")
            return nil
        }
        let tuples:[String] = data!.data
        if tuples.count > 0 {
            return tuples[0]
        }
        else {
            Logger.logger.reportError(self, "No first col for key:[\(key)]")
            return nil
        }
    }


}
