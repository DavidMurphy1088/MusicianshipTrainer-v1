import Foundation

class ExampleDataRow {
    var type:String
    var data:[String]
    init(type:String, data:[String]) {
        self.type = type
        self.data = data
    }
}

class ExampleData : ObservableObject {
    static var shared = ExampleData()
    var logger = Logger.logger
    private var dataDictionary:[String: ExampleDataRow ] = [:]
    private let googleAPI = GoogleAPI.shared
    
    @Published var dataStatus:RequestStatus = .waiting

    private init() {
        self.dataStatus = .waiting
        loadData()
    }
    
    func loadData() {
        dataDictionary = [:]
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
                        self.logger.log(self, "loaded \(self.dataDictionary.count) example rows")
                    }
                    catch {
                        self.logger.log(self, "failed load \(self.dataDictionary.count) example rows")
                    }
                }
                else {
                    self.setDataReady(way: .failed)
                    self.logger.log(self, "failed load \(self.dataDictionary.count) example rows")
                }
            }
            else {
                self.setDataReady(way: status)
            }
        }
    }
    
    //load data from Google Drive Sheet
    func loadSheetData(sheetRows:[[String]]) {
        var keyPath:[String] = []
        
        ///set according to the format of the examples Sheet
        let keyOffsetStart = 1 //start of path offset
        let keyDepth = 5 //num columns representing the structure key
        let typeOffset = keyOffsetStart + keyDepth
        let typeDepth = 1
        let dataOffsetStart = typeOffset + typeDepth  + 1   //start of data
        var rowNum = 0
        
        for rowCells in sheetRows {
            rowNum += 1
//            if rowNum > 14 {
//                rowNum = rowNum + 0
//            }
            if rowCells.count == 0 {
                continue
            }
            let type = rowCells[0]
            if type == "//" {
                continue
            }

            var rowData:[String] = []
            var rowType:String? = nil

            for i in 0..<rowCells.count {
                if i<keyOffsetStart {
                    continue
                }
                let cell = rowCells[i]

                if i <= keyDepth {
                    if !cell.isEmpty {
                        if keyPath.count > 0 {
                            keyPath = Array(keyPath.prefix(i-1))
                        }
                        keyPath.append(cell)
                    }
                }
                if i == typeOffset {
                    rowType = ("\(cell)")
                }
                if i >= dataOffsetStart {
                    rowData.append("\(cell.replacingOccurrences(of: " ", with: ""))")
                }
            }
            var key = ""
            for i in 0..<keyPath.count {
                key += keyPath[i]
                if i < keyPath.count - 1 {
                    key += "."
                }
            }
            if !key.isEmpty {
                 self.dataDictionary[key] = ExampleDataRow(type: rowType ?? "", data: rowData)
            }
        }
        loadContentSections()
    }
    
    ///Create the nested content sections with their child sections
    func loadContentSections() {
        var parents:[Int : ContentSection] = [:]
        for key in self.dataDictionary.keys.sorted() {
            let keyLevel = key.filter { $0 == "." }.count  //NZMEB is level 1 with parent the root
            
            //Maybe comment but dont delete...
//            print("\n", String(repeating: " ", count: 3 * keyLevel),
//                  "exampleData.data \(key) \ttype:\(self.dataDictionary[key]?.type) data:\(self.dataDictionary[key]?.data)")

            var parentSection:ContentSection
            if keyLevel == 0 {
                parentSection = MusicianshipTrainerApp.root
            }
            else {
                parentSection = parents[keyLevel-1]!
            }
            let components = key.components(separatedBy: ".")
            if components.count == 0 {
                logger.reportError(self, "Invalid path \(key)")
            }
            let name = components[components.count-1]
            let dictionaryData = self.dataDictionary[key]
            var type = ""
            var instructions:String? = nil
            if let data = dictionaryData {
                type = data.type
                if type == "I" {
                    instructions = data.data[0]
                }
            }
            let section = ContentSection(parent: parentSection, name: name, type: type, instructions: instructions, tipsAndTricks: "")
            parentSection.subSections.append(section)
            parents[keyLevel] = section
        }
    }
    
    func setDataReady(way:RequestStatus) {
        DispatchQueue.main.async {
            self.dataStatus = way
        }
    }
    
    func get(contentSection:ContentSection) -> [Any]! {
//        var current = contentSection
//        var key = ""
//        while true {
//            key = current.name + key
//            let par = current.parent
//            if par == nil {
//                break
//            }
//            current = par!
//            key = "." + key
//        }
        //return getData(key: contentSection.name)
        return getData(key: contentSection.getPath(), type: contentSection.type)
    }
    
    func getData(key:String, type:String, warnNotFound:Bool=true) -> [Any]! {
        let data = self.dataDictionary[key]
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
