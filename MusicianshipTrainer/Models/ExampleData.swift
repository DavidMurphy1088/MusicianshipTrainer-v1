import Foundation

class ExampleDataRow {
    var type:String
    var data:[String]
    var row:Int
    init(row:Int, type:String, data:[String]) {
        self.row = row
        self.type = type
        self.data = data
    }
}

class ExampleData : ObservableObject {
    static var shared = ExampleData()
    var logger = Logger.logger
    private var loadedDataDictionary:[String: ExampleDataRow ] = [:]
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
        let keyStart = 1 //start column of key
        //let keyStartLicense = 3 //start column of key to keep for this license
        let keyEnd = 5 //
        var keyPathParts:[String] = Array(repeating: "", count: keyEnd - keyStart + 1)

        let typeColumnStart = keyEnd + 2
        let dataOffsetStart = keyEnd + 4   //start of data
        var rowNum = 0
        
        for rowCells in sheetRows {
            rowNum += 1
            if rowCells.count == 0 {
                continue
            }
            let type = rowCells[0]
            if type.hasPrefix("//")  {
                continue
            }

            var rowData:[String] = []
            var rowType:String = ""
            var rowIsBlank = true
            var rowHasData = false
            //print ("===>", rowNum, keyPathParts)
            
            for i in 0..<rowCells.count {
                if i<keyStart {
                    continue
                }
                
                let cell = rowCells[i]
                let cellData = cell.replacingOccurrences(of: " ", with: "")
                if !cellData.isEmpty {
                    rowIsBlank = false
                }
                if cell == "Exam Mode" {
                    let xx = 1
                }

                if i >= keyStart && i <= keyEnd {
                    if !cell.isEmpty {
                        keyPathParts[i - keyStart] = cell                        
                        //clear the key to the right
                        for j in i - keyStart+1..<keyPathParts.count {
                            keyPathParts[j] = ""
                        }
                    }
                }
                
                if i == typeColumnStart {
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

            var key:String? = ""
            for i in 0..<keyPathParts.count {
                let path = keyPathParts[i]
                if i==0 && path != "NZMEB" {
                    key = nil
                    break
                }
                if i==1 && path != "Grade 1" {
                    key = nil
                    break
                }
                key! += path
                if i < keyPathParts.count - 1 {
                    key! += "."
                }
            }
            
            if let key = key {
                self.loadedDataDictionary[key] = ExampleDataRow(row: rowNum, type: rowType, data: rowData)
            }
        }
        for k in self.loadedDataDictionary.keys.sorted() {
            print("loadSheetData::", k)
        }
        loadContentSections()
    }
    
    func arrayToKeyStr(_ parts:[String]) -> String {
        var str = ""
        for p in parts {
            str += "." + p
        }
        return str
    }
    
    ///Create the nested content sections with their child sections
    func loadContentSections() {
        var parents:[String : ContentSection] = [:]
        
        for loadedDictionaryKey in self.loadedDataDictionary.keys.sorted() {
            
            //discard the content for the unlicensed parts of the key
            var allKeyParts = loadedDictionaryKey.split(separator: ".")
            var keyParts:[String] = []
            for i in 2..<allKeyParts.count {
                keyParts.append(String(allKeyParts[i]))
            }
            
            //print(keyParts)
            for i in 0..<keyParts.count {
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
                if !hasSubsection {
                    let loadedData = self.loadedDataDictionary[loadedDictionaryKey]
                    let contentSection = ContentSection(parent: parentSection, name: keyParts[i],
                                                        type: loadedData!.type,
                                                        loadedDictionaryKey: loadedDictionaryKey,
                                                        loadedRow: loadedData!.row)
                    parentSection.subSections.append(contentSection)
                    //present the sections in the order in which they were loaded from the Sheet (not alpahbetically...)
                    let sorted:[ContentSection] = parentSection.subSections.sorted { (c1, c2) -> Bool in
                        return c1.loadedRow < c2.loadedRow
                    }
                    parentSection.subSections = sorted
                    
                    let dictKey = "."+contentSection.getPath()
                    parents[dictKey] = contentSection
                    
                    let keyLevel = dictKey.components(separatedBy: ".").count
                    //Comment maybe but dont delete.
                    print("\n", String(repeating: " ", count: 4 * (keyLevel-1)),
                          "ContentSection--> key:[\(loadedDictionaryKey)] \tname:[\(contentSection.name)]  \trow:\(loadedData?.row) type:\(loadedData?.type) Row:\(loadedData?.row)") //\tdata:\(loadedData?.data)")

                }
            }
        }
    }

    func setDataReady(way:RequestStatus) {
        DispatchQueue.main.async {
            self.dataStatus = way
        }
    }
    
    func get(contentSection:ContentSection) -> [Any]! {

        return getData(key: contentSection.loadedDictionaryKey, type: contentSection.type)
    }
    
    func getType(key:String) -> String? {
        let data = self.loadedDataDictionary[key]
        guard data != nil else {
            Logger.logger.reportError(self, "No type for key:[\(key)]")
            return nil
        }
        return data!.type
    }
    
    func getFirstCol(key:String) -> String? {
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

    func getData(key:String, type:String, warnNotFound:Bool=true) -> [Any]! {
        let data = self.loadedDataDictionary[key]
        guard data != nil else {
            if warnNotFound {
                Logger.logger.reportError(self, "No data for key:[\(key)]")
            }
            return nil
        }
        //let tuples:[String] = data!
        let tuples:[String] = data!.data
        
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
                Logger.logger.reportError(self, "Unknown time signature tuple at \(i) :  \(key) \(tuple)")
                continue
            }
            if i == 2 {
                if parts.count == 1 {
                    if let lines = Int(parts[0]) {
                        result.append(StaffCharacteristics(lines: lines))
                        continue
                    }
                }
                Logger.logger.reportError(self, "Unknown staff line tuple at \(i) :  \(key) tuple:[\(tuple)]")
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
            Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(key) \(tuple)")
        }
        return result
    }

}
