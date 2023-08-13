import SwiftUI
struct TestView: View {

    let googleAPI = GoogleAPI.shared
    @ObservedObject var logger = Logger.logger
    let numbers = Array(1...10)
    @State private var currentIndex = 0

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

            if logger.errorNo >= 0 {
                Text("Error no \(logger.errorNo)")
            }
            if let err = logger.errorMsg {
                Text("Error:\(err)").padding()
            }
            
            HStack {
                Button(action: {
                    Cache.shared.clearCache()
                    ExampleData.shared1.loadData()
                }) {
                    Text("Refresh Content").padding()
                }.padding()
                
                Button(action: {
                    logger.reportError(String("") as AnyObject, "test error")
                }) {
                    Text("Induce Error").padding()
                }
                Button(action: {
                    //let fileId = "1U6KbcXardwnRzW7nuLbD2XCWXTqo5Vad"
                    let fileId = "1Eg9zeF7fsPFNxXwMQQWKCQjOa3cZCgRb" //NZMEB.Grade 1.Intervals Visual.Instructions
                    let request = DataRequest(callType: .file, id: fileId, context: "TestView.byId", targetExampleKey: nil)
                    
                    googleAPI.getDataByID(request: request) {status, data in
                        print(status)
                        print(String(data: data!, encoding: .utf8) ?? "")
                    }
                }) {
                    Text("Google File By ID").padding()
                }
                
                Button(action: {
                    //requires files parent folder id in plist GoogleDriveDataFolderID
                    let name = "TestTipsTricks"
                    googleAPI.getDocumentByName(contentSection: ContentSection(parent: nil, name: "test", type: "", isActive: false), name: name) {status,data in
                        print("TESTVIEW getDocumentByName:", status, "data:", data ?? "")
                    }
                    
                }) {
                    Text("Get Document by Name").padding()
                }
            }
            .padding(.horizontal)
        }
    }
    

    struct ChildView: View {
        let number: Int
        @Binding var currentIndex: Int
        let maxIndex: Int
        
        var body: some View {
            VStack {
                Text("Child View \(number)")
                
                if currentIndex < maxIndex {
                    Button(action: {
                        currentIndex += 1
                    }) {
                        Text("Go to Next Child View")
                    }
                }
            }
        }
    }

}

