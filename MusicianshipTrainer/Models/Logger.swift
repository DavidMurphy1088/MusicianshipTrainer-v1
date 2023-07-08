import Foundation

class Logger : ObservableObject {
    static var logger = Logger()
    @Published var status:String = ""
    @Published var isError:Bool = false

    func reportError(_ reporter:AnyObject, _ context:String, _ err:Error? = nil) {
        var msg = String("🛑 *** ERROR *** :" + String(describing: type(of: reporter))) + " " + context
//        if let err = err {
//            msg += String()
//        }
        if let err = err {
            print(msg, err.localizedDescription)
        }
        else {
            print(msg)
        }
        publish(msg, true)
    }
    
    func log(_ reporter:AnyObject, _ msg:String) {
        let msg = String(describing: type(of: reporter)) + ":" + msg
        print(msg)
        if !MusicianshipTrainerApp.productionMode {
            publish(msg, false)
        }
    }
    
    func publish(_ msg:String, _ isErr:Bool) {
        DispatchQueue.global(qos: .background).async {
            //print(msg)
            self.status = msg
            self.isError = isErr
        }
    }
}
