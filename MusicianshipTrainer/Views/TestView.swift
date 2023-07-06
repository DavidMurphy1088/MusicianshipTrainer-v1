import SwiftUI

struct TestView: View {
//    var score:Score
//    @ObservedObject var staff:Staff
//    @ObservedObject var ts:TimeSlice
    let firebase = FirestorePersistance()
    let spreadsheet = GoogleSpreadsheet()

    init() {
//        score = Score(timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
//        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
//        self.score.setStaff(num: 0, staff: staff)
//        let ts = score.addTimeSlice()
//        ts.addNote(n: Note(num: 72))
//        self.ts = ts
//        self.staff = staff
    }
    
    var body: some View {
        VStack {
            //Text("test")
            //ToolsView(score: score)
            //ScoreView(score: score).padding()
            
//            StaffView(score: score, staff: staff, staffLayoutSize: StaffLayoutSize(lineSpacing:20)).padding().border(Color.blue)
            
            //Text("Ts:: \(tagText())")
//            
//            StaffNotesView(score: score, staff: staff, lineSpacing: StaffLayoutSize(lineSpacing: 20))
//                //.border(Color.indigo)
//                .frame(width: 5 * Double(ts.notesLength ?? 0) + 200)
            Spacer()
            
            Button(action: {
                spreadsheet.get() { data, status in
                    // Handle the result from F1
                    print("Received data: \(data)")
                }
            }) {
                Text("Google ").padding()
            }
            
            Spacer()
            
            Button(action: {
                firebase.driveTest()
            }) {
                Text("FireStore").padding()
            }
            
            Spacer()
        }
    }
}

