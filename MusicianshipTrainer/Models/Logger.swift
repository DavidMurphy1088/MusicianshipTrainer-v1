import Foundation

class Logger : ObservableObject {
    static var logger = Logger()
    @Published var loggedMsg:String? = nil
    @Published var errorNo:Int = 0
    @Published var errorMsg:String? = nil
    
    private init() {
        
    }
    
    func reportError(_ reporter:AnyObject, _ context:String, _ err:Error? = nil) {
        var msg = String("🛑 *** ERROR *** ErrNo:\(errorNo): " + String(describing: type(of: reporter))) + " " + context
        if let err = err {
            msg += ", "+err.localizedDescription
        }
        print(msg)
        DispatchQueue.main.async {
            //print("===>Logger::publishing", self.id.uuidString.prefix(8), msg)
            self.errorMsg = msg
            self.errorNo += 1
        }
    }
    
    func reportErrorString(_ context:String, _ err:Error? = nil) {
        reportError(self, context, err)
    }

    func log(_ reporter:AnyObject, _ msg:String) {
        let msg = String(describing: type(of: reporter)) + ":" + msg
        print("-->", msg)
        if !MusicianshipTrainerApp.productionMode {
            DispatchQueue.main.async {
                self.loggedMsg = msg
            }
        }
    }
    
}
