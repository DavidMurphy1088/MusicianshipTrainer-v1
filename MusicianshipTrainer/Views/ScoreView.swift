import SwiftUI
import CoreData
import MessageUI

struct FeedbackView: View {
    @ObservedObject var score:Score
    var body: some View {
        HStack {
            if let studentFeedback = score.studentFeedback {
                if studentFeedback.correct {
                    Image(systemName: "checkmark.circle")
                        .scaleEffect(2.0)
                        .foregroundColor(Color.green)
                        .padding()
                }
                else {
                    Image(systemName: "xmark.octagon")
                        .scaleEffect(2.0)
                        .foregroundColor(Color.red)
                        .padding()
                }
                if let index = studentFeedback.indexInError {
                        Text("Wrong rhythm here")// at note: \(index)").padding()
                }
            }
        }
        if let studentFeedback = score.studentFeedback {
            if let feedbackExplanation = studentFeedback.feedbackExplanation {
                VStack {
                    Text(feedbackExplanation)
                        .lineLimit(nil)
                }
            }
            if let feedbackNote = studentFeedback.feedbackNote {
                VStack {
                    Text(feedbackNote)
                        .lineLimit(nil)
                }
            }
        }
    }
}

struct ScoreView: View {
    @ObservedObject var score:Score
    @ObservedObject var staffLayoutSize:StaffLayoutSize
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(score:Score) {
        self.score = score
        self.staffLayoutSize = StaffLayoutSize(lineSpacing: UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0)
//<<<<<<< HEAD
        self.staffLayoutSize.lineSpacing = 0.0
//=======
//>>>>>>> main
        setOrientationLineSize(ctx: "ScoreView::init")
        //print("SCORE VIEW INIT", "width::", UIScreen.main.bounds.width, "line spacing", lineSpacing.value)
    }
    
    func getFrameHeight() -> Double {
        //Score tells the staff how high to make itself. Child views of staff (all paths, moves, linesto sec) do not have
        //inherent sizes that they can pass back up the parent staff view. So Score sets the sizes itself
        
        var height = 0.0
        var lastStaff:Staff? = nil
        for staff in score.staffs {
            if !staff.isHidden {
                if lastStaff != nil {
                    //height += 1 //getStaffHeight() / 2.0 //Let user views specify padding around a Score view (rather than specifying padding here)
                }
                height += staffLayoutSize.lineSpacing
            }
            lastStaff = staff
        }
        return height
    }
    
    func setOrientationLineSize(ctx:String) {
        //Absolutley no idea - the width reported here decreases in landscape mode so use height (which increases)
        //https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
//<<<<<<< HEAD
        var lineSpacing:Double
        if self.staffLayoutSize.lineSpacing == 0 {
            lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
        }
        else {
            //make a small change only to force via Published a redraw of the staff views
            lineSpacing = self.staffLayoutSize.lineSpacing
            if UIDevice.current.orientation.isLandscape {
                lineSpacing += 1
            }
            else {
                lineSpacing -= 1
            }
        }
//
//        print("\nSET ORIENTATION \tfrom", ctx, terminator: "")
//        if UIDevice.current.orientation.isLandscape {
//            print("\tLandscape", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        else {
//            print("\tPortrait", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        print("  \twidth::", UIScreen.main.bounds.width, "height:", UIScreen.main.bounds.height, "\tline spacing", lineSpacing)
        self.staffLayoutSize.setLineSpacing(lineSpacing)
//=======

        let ls = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
//        if UIDevice.current.orientation.isLandscape {
//            print("\tLandscape", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        else {
//            print("\tPortrait", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        print("  \twidth::", UIScreen.main.bounds.width, "height:", UIScreen.main.bounds.height, "\tline spacing", ls)
        self.staffLayoutSize.setLineSpacing(ls)
//>>>>>>> main
    }
    
    var body: some View {
        VStack {
            FeedbackView(score: score)
            
            ForEach(score.getStaff(), id: \.self.type) { staff in
                if !staff.isHidden {
                    StaffView(score: score, staff: staff, staffLayoutSize: staffLayoutSize)
                        .frame(height: staffLayoutSize.getStaffHeight(score: score))
                }
            }
        }
        .onAppear {
            //self.lineSpacing.lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
            self.setOrientationLineSize(ctx: "onAppear")
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { orientation in
            setOrientationLineSize(ctx: "orientationDidChangeNotification")
         }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }

        .coordinateSpace(name: "Score1")
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .background(UIGlobals.backgroundColor)
        //.border(Color .red, width: 4)
        .frame(height: getFrameHeight())
    }

}

