import Foundation

class ExampleData : ObservableObject {
    static var shared = ExampleData()
    var logger = Logger.logger
    private var data:[String: [String]] = [:]
    private let googleAPI = GoogleAPI()
    
    @Published var dataStatus:RequestStatus = .waiting

    private init() {
        self.dataStatus = .waiting
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
                        self.loadData(data: sheetRows)
                        self.setDataReady(way: status)
                        self.logger.log(self, "loaded \(self.data.count) example rows")
                    }
                    catch {
                        self.logger.log(self, "failed load \(self.data.count) example rows")
                    }
                }
                else {
                    self.setDataReady(way: .failed)
                    self.logger.log(self, "failed load \(self.data.count) example rows")
                }
            }
            else {
                self.setDataReady(way: status)
            }
        }
    }
    
    //load data from Google Drive Sheet
    func loadData(data:[[String]]) {
        var keyPath:[String] = []
        
        ///set according to the format of the examples Sheet
        let keyOffsetStart = 1 //start of path offset
        let keyDepth = 4 //num columns representing the structure key
        let dataOffsetStart = 6 //start of path offset

        for rowCells in data {
            if rowCells.count == 0 {
                continue
            }
            let type = rowCells[0]
            if type == "//" {
                continue
            }

            var rowData:[String] = []
            
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
                if i >= dataOffsetStart {
                    rowData.append("\(cell)")
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
                self.data[key] = rowData
            }
        }
        loadContentSections()
    }
    
    func loadContentSections() {
        var parents:[Int : ContentSection] = [:]
        for key in self.data.keys.sorted() {
            let keyLevel = key.filter { $0 == "." }.count  //NZMEB is level 1 with parent the root
            //print(String(repeating: " ", count: 3 * keyLevel), "exampleData.data \(key) data:\(self.data[key])")

            var parentSection:ContentSection
            if keyLevel == 0 {
                parentSection = MusicianshipTrainerApp.root
            }
            else {
                parentSection = parents[keyLevel-1]!
            }
            let section = ContentSection(parent: parentSection, type: .example, name: key)
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
        return getData(key: contentSection.name)
    }
    
    func getData(key:String, warnNotFound:Bool=true) -> [Any]! {
        return getDataCloud(key: key, warnNotFound: warnNotFound)
    }
    
    func getDataCloud(key:String, warnNotFound:Bool=true) -> [Any]! {
        let data = self.data[key]
        guard data != nil else {
            if warnNotFound {
                Logger.logger.reportError(self, "No data for key:[\(key)]")
            }
            return nil
        }
        let tuples:[String] = data!

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
                Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(key) \(tuple)")
                continue
            }
            if i == 2 {
                if parts.count == 1 {
                    if let lines = Int(parts[0]) {
                        result.append(StaffCharacteristics(lines: lines))
                        continue
                    }
                }
                Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(key) \(tuple)")
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
                let notePitch:Int? = Int(parts[0])
                if let notePitch = notePitch {
                    let value = Double(parts[1]) ?? 1
                    result.append(Note(num: notePitch, value: value))
                }
                continue
            }
            Logger.logger.reportError(self, "Unknown tuple at \(i) :  \(key) \(tuple)")
        }
        return result
    }
    
//        instr += "\n\u{2022} Dotted Minim / Three Quarter Note"
//        instr += "\n\u{2022} Semibreve / Whole Note"
//
//        data["Grade 1.Clapping.Instructions"] = instr
//        data["Grade 1.Clapping.Hints"] = "Hints - Good luck!"
//
//        data["Grade 1.Playing.Instructions"] = "In the exam you will be given around 30 seconds to look at a melody in either the key of C Major or G Major. During this time you may play through the piece. Use your right hand to play the melody, and your left hand to play the tonic chord with the last note."
//        data["Grade 1.Playing.Hints"] = "Hints - Good luck!"
//
//        data["Grade 1.Intervals Aural.Instructions"] = "In the exam, the examiner will play two notes, first separately and then together. You will be expected to answer whether the interval is a second or a third."
//        data["Grade 1.Intervals Aural.Hints"] = "Hints - Good luck!"
//
//        data["Grade 1.Echo Clap.Instructions"] = "In the exam, the examiner will clap a four-bar rhythm in 2/4 time or 3/4 time. You will be expected to clap the rhythm pattern back to the examiner. A second attempt will be allowed if necessary."
//        data["Grade 1.Echo Clap.Hints"] = "Hints - Good luck!"
//
//        // =========== Examples
//
//        data["Grade 1.Intervals Visual.Example 1"] = "(TS,3,4) (72,1) (74,2)"
//        data["Grade 1.Intervals Visual.Example 2"] = "(TS,4,4) (74,2) (71,2)"
//        data["Grade 1.Intervals Visual.Example 3"] = "(TS,3,4) (69,1) (67,2)"
//        data["Grade 1.Intervals Visual.Example 4"] = "(TS,2,4) (67,1) (64,1)"
//        data["Grade 1.Intervals Visual.Example 5"] = "(TS,3,4) (69,1) (72,2)"
//        data["Grade 1.Intervals Visual.Example 6"] = "(TS,C) (69,2) (72,2)"
//
//        data["Grade 1.Playing.Example 1"] = "(TS,4,4) (64,1) (62,1) (60,.5) (62,.5) (64,1) (B) (67,2) (67,2) (B) (65,1) (67,1) (64,1) (62,1) (B) (60,4) "
//        data["Grade 1.Playing.Example 2"] = "(TS,3,4) (67,1) (65,1) (64,1) (B) (65,1) (64,1) (62,.5) (60,.5) (B) (64,2) (67,1) (B) (60,3) "
//        data["Grade 1.Playing.Example 3"] = "(K) (TS,3,4) (67,1) (69,1) (71,1) (B) (72,1) (71,1) (69,1) (B) (71,2) (69,1) (B) (67,3) "
//        data["Grade 1.Playing.Example 4"] = "(K) (TS,4,4) (71,1) (67,.5) (69,.5) (71,1) (72,1) (B) (74,1) (72,1) (71,1) (69,1) (B) (71,2) (72,1) (69,1) (B) (67,4)"
//        data["Grade 1.Playing.Example 5"] = "(K) (TS,3,4) (67,1) (69,1) (71,1) (B) (74,2) (71,1) (B) (72,.5) (74,.5) (71,1) (69,1) (B) (67,3)"
//        data["Grade 1.Playing.Example 6"] = "(TS,4,4) (67,1) (65,1) (64,1) (62,1) (B) (60,1) (64,1) (65,1) (67,1) (B) (65,2) (62,2) (B) (60,4)"
//        data["Grade 1.Playing.Example 7"] = "(TS,4,4) (72,2) (72,2) (B) (76,1) (74,1) (72,2) (B) (74,.5) (76,.5) (79,2) (76,1) (B) (72,4)"
//        data["Grade 1.Playing.Example 8"] = "(K) (TS,3,4) (67,1) (69,1) (71,1) (B) (72,1) (74,2) (B) (71,2) (69,1) (B) (67,3)"
//        data["Grade 1.Playing.Example 9"] = "(K) (TS,4,4) (67,1) (71,1) (74,2) (B) (72,2) (71,2) (B) (72,1) (74,.5) (72,.5) (71,1) (69,1) (B) (67,4)"
//        data["Grade 1.Playing.Example 10"] = "(TS,4,4) (79,1) (76,1) (72,2) (B) (74,2) (76,2) (B) (77,1) (79,2) (76,1) (B) (72,4)"
//
//        //data["Grade 1.Playing.Example 7"] = "(K) (TS,3,4) () () () () () () () () () () () () () () () () () () () () () () () () ()"
//
//        data["Grade 1.Clapping.Example 1"] = data["Grade 1.Playing.Example 1"]
//        data["Grade 1.Clapping.Example 2"] = data["Grade 1.Playing.Example 2"]
//        data["Grade 1.Clapping.Example 3"] = data["Grade 1.Playing.Example 3"]
//        data["Grade 1.Clapping.Example 4"] = data["Grade 1.Playing.Example 4"]
//        data["Grade 1.Clapping.Example 5"] = data["Grade 1.Playing.Example 5"]
//        data["Grade 1.Clapping.Example 6"] = data["Grade 1.Playing.Example 6"]
//        data["Grade 1.Clapping.Example 7"] = data["Grade 1.Playing.Example 7"]
//        data["Grade 1.Clapping.Example 8"] = data["Grade 1.Playing.Example 8"]
//        data["Grade 1.Clapping.Example 9"] = data["Grade 1.Playing.Example 9"]
//        data["Grade 1.Clapping.Example 10"] = data["Grade 1.Playing.Example 10"]
//
//        data["Grade 1.Intervals Aural.Example 1"] = "(72,1) (74,1)"
//        data["Grade 1.Intervals Aural.Example 2"] = "(74,1) (76,1)"
//        data["Grade 1.Intervals Aural.Example 3"] = "(72,1) (76,1)"
//        data["Grade 1.Intervals Aural.Example 4"] = "(65,1) (69,1)"
//
//        data["Grade 1.Echo Clap.Example 1"] = "(TS,3,4) (71,2) (71,1) (B) (71,1) (71,1) (71,1) (B) (71,2) (71,1) (B) (71,3))"
//        data["Grade 1.Echo Clap.Example 2"] = "(TS,3,4) (71,1) (71,.5) (71,.5) (71,1) (B) (71,2) (71,1) (B) (71,1) (71,.5) (71,.5) (71,1) (B) (71,3)"
//        data["Grade 1.Echo Clap.Example 3"] = "(TS,3,4) (71,1) (71,1) (71,1) (B) (71,3) (B) (71,1) (71,1) (71,1) (B) (71,2) (71,1)"
//        data["Grade 1.Echo Clap.Example 4"] = "(TS,3,4) (71,1) (71,.5) (71,.5) (71,.5) (71,.5) (B) (71,1) (71,1) (71,1) (B) (71,2) (71,1) (B) (71,3)"
//        data["Grade 1.Echo Clap.Example 5"] = "(TS,3,4) (71,1) (71,2) (B) (71,1) (71,2) (B) (71,1) (71,1) (71,1) (B) (71,3)"
//
//        data["Grade 1.Echo Clap.Example 6"] = "(TS,2,4) (71,1) (71,.5) (71,.5) (B) (71,1) (71,1) (B) (71,1) (71,.5) (71,.5) (B) (71,2)"
//        data["Grade 1.Echo Clap.Example 7"] = "(TS,2,4) (71,.5) (71,.5) (71,.5) (71,.5) (B) (71,1) (71,1) (B) (71,.5) (71,.5) (71,.5) (71,.5) (71,2)"
//        data["Grade 1.Echo Clap.Example 8"] = "(TS,2,4) (71,1) (71,1) (B) (71,.5) (71,.5) (71,1) (B) (71,.5) (71,.5) (71,1) (B) (71,2)"
//        data["Grade 1.Echo Clap.Example 9"] = "(TS,2,4) (71,.5) (71,.5) (71,1) (B) (71,.5) (71,.5) (71,1) (B) (71,1) (71,1) (B) (71,2)"
//        data["Grade 1.Echo Clap.Example 10"] = "(TS,2,4) (71,1) (71,1) (B) (71,.5) (71,.5) (71,.5) (71,.5) (B) (71,1) (71,.5) (71,.5) (B) (71,2)"
//
//        //data["Intervals Visual.test"] = data["Grade 1.Intervals Visual.Example 1"]
//        //data["Playing.test"] = data["Grade 1.Playing.Example 1"]
//        //data["Clapping.test"] = data["Grade 1.Playing.Example 1"]
//
//        data["test_interval"] = data["Grade 1.Intervals Visual.Example 1"]
//        data["test_clap"] = "(K) (TS,4,4) (71,1) (B) (67,.5) (69,.5) (71,1) (72,1) (B) (74,1)"
//        data["test_aural_interval"] = data["Grade 1.Intervals Visual.Example 1"]
//
//        //data["test"]  = "(TS,3,4) (67,1) (65,1) (64,1) (B) (65,1) (64,1) (62,.5) (60,.5) (B) (64,2) (67,1) (B) (60,3) "
//        //data["test"]  = "(72,1) (72,.5) (74,.5) (72,1)"
//        data["test"]  = "(67,.5) (69,.5) (71,2)"
//    }
//

}
