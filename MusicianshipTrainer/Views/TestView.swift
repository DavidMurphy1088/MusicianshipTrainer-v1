import SwiftUI
//import GoogleSignIn
//import GoogleSignInSwift

struct TestView: View {

    let googleAPI = GoogleAPI()
    @ObservedObject var logger = Logger.logger

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
                //Spacer()
            if logger.errorNo >= 0 {
                Text("Error no \(logger.errorNo)")
            }
            if let err = logger.errorMsg {
                Text("Error:\(err)").padding()
            }
            
            //Spacer()
            
            Button(action: {
                logger.reportError(String("") as AnyObject, "test error")
            }) {
                Text("Induce Error").padding()
            }

            Button(action: {
                //let fileId = "1U6KbcXardwnRzW7nuLbD2XCWXTqo5Vad"
                let fileId = "1Eg9zeF7fsPFNxXwMQQWKCQjOa3cZCgRb" //NZMEB.Grade 1.Intervals Visual.Instructions

                googleAPI.getFileByID(fileId: fileId) {status, data in
                    print(status)
                    print(data)
                }
            }) {
                Text("Google Drive File").padding()
            }
            
            Button(action: {
                googleAPI.getExampleSheet() { status, data in
                    print("Received data: \(status) \(data)")
                }
            }) {
                Text("Google Examples Sheet").padding()
            }
                
                //Spacer()
        }
    }
}

