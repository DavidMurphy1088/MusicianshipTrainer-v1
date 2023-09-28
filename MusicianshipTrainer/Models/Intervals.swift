import Foundation

class IntervalType : Comparable, Hashable {
    var intervals:[Int]
    var name:String
    var explanation:[String]

    static func == (lhs: IntervalType, rhs: IntervalType) -> Bool {
        if lhs.intervals.count > 0 && rhs.intervals.count > 0  {
            return lhs.intervals[0] == rhs.intervals[0]
        }
        else {
            return false
        }
        
    }

    static func < (lhs: IntervalType, rhs: IntervalType) -> Bool {
        if lhs.intervals.count > 0 && rhs.intervals.count > 0  {
            return lhs.intervals[0] < rhs.intervals[0]
        }
        else {
            return false
        }
    }

    init(intervals:[Int], name:String, explanation:[String]) {
        self.intervals = intervals
        self.name = name
        self.explanation = explanation
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class Intervals {
    var intervalTypes:[IntervalType]
    var intervalsPerColumn:Int
    
    init(grade:Int) {
        self.intervalTypes = []
        if grade >= 1 {
            intervalTypes.append(IntervalType(intervals:[1,2], name: "Second", explanation: ["",""]))
            intervalTypes.append(IntervalType(intervals:[3,4], name: "Third", explanation: [""]))
        }
        if grade >= 2 {
            intervalTypes.append(IntervalType(intervals:[5,6], name: "Fourth", explanation: ["",""]))
            intervalTypes.append(IntervalType(intervals:[7], name: "Fifth", explanation: [""]))
        }
//        if grade >= 3 {
//            intervalTypes.append(IntervalType(intervals:[8,9], name: "Sixth", explanation: ["",""]))
//            intervalTypes.append(IntervalType(intervals:[10,11], name: "Seventh", explanation: [""]))
//            intervalTypes.append(IntervalType(intervals:[12], name: "Octave", explanation: [""]))
//        }
        self.intervalsPerColumn = Int(Double((self.intervalTypes.count + 1)) / 2.0)
        if intervalsPerColumn == 0 {
            intervalsPerColumn = 1
        }
    }
    
    func getInterval(intervalName:String) -> IntervalType? {
        //let result = self.intervalTypes.first(where: {$0.intervals.contains(intervalName)})
        for intervalType in intervalTypes {
            if intervalType.name == intervalName {
                return intervalType
            }
        }
        return nil
    }
    
    func getVisualColumnCount() -> Int {
        return (intervalTypes.count + self.intervalsPerColumn/2) / self.intervalsPerColumn
    }
    
    func getVisualColumns(col:Int) -> [IntervalType] {
        var result:[IntervalType] = []
        let start = col * intervalsPerColumn
        for i in 0..<intervalsPerColumn {
            let index = i + col * intervalsPerColumn
            if index < intervalTypes.count {
                result.append(intervalTypes[index])
            }
        }
        return result
    }
}
