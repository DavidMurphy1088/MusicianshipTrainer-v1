import Foundation

class Logger : ObservableObject {
    static var logger = Logger()
    @Published var loggedMsg:String = ""
    var errorNo:Int = 0
    @Published var errorMsg:String = ""
    
    func reportError(_ reporter:AnyObject, _ context:String, _ err:Error? = nil) {
        var msg = String("🛑 *** ERROR *** \(errorNo):" + String(describing: type(of: reporter))) + " " + context
        if let err = err {
            msg += ", "+err.localizedDescription
        }
        print(msg)
        DispatchQueue.main.async {
            //print("Logger::publishing", msg)
            self.errorMsg = msg
        }
//        let backgroundQueue = DispatchQueue.global(qos: .background)
        //Logger wont update the entry screen = NO IDEA WHY :(:(:(:(:(:(:(:(:(:(:(:(
//        backgroundQueue.async {
//            while (true) {
//                sleep(2)
//                self.test()
//            }
//        }
    }
    
//    func test() {
//        self.errorNo += 1
//        DispatchQueue.main.async {
//            //sleep(5)
//            print("Logger::publishing", self.errorNo)
//            self.errorMsg = "test \(self.errorNo)"
//            self.loggedMsg = "testlogged \(self.errorNo)"
//            //self.loggedMsg = msg
//            //self.isError = isErr
//        }
//    }
    
    func log(_ reporter:AnyObject, _ msg:String) {
        let msg = String(describing: type(of: reporter)) + ":" + msg
        print(msg)
        if !MusicianshipTrainerApp.productionMode {
            DispatchQueue.main.async {
                self.loggedMsg = msg
            }
        }
    }
    
}
