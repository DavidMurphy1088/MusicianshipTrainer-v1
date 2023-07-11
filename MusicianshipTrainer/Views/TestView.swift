import SwiftUI
//import GoogleSignIn
//import GoogleSignInSwift

struct TestView: View {
//    var score:Score
//    @ObservedObject var staff:Staff
//    @ObservedObject var ts:TimeSlice
    //let firebase = FirestorePersistance()
    let spreadsheet = GoogleAPI()
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
    
//    func handleSignInButton() {
//    //https://developers.google.com/identity/sign-in/ios/sign-in
//      GIDSignIn.sharedInstance.signIn(
//        withPresenting: rootViewController) { signInResult, error in
//          guard let result = signInResult else {
//            // Inspect error
//            return
//          }
//          // If sign in succeeded, display the app's main content View.
//        }
//      )
//    }

    
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
            if logger.errorMsg != "" {
                Text("Error:\(logger.errorMsg)").padding()
            }

            Spacer()
            
            Button(action: {
                spreadsheet.createJWTToken()
            }) {
                Text("Google Drive File").padding()
            }

            Button(action: {
                spreadsheet.getExampleSheet() { status, data in
                    print("Received data: \(status) \(data)")
                }
            }) {
                Text("Google Examples Sheet").padding()
            }

            Spacer()
        }
    }
}

