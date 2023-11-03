import SwiftUI
import CoreData
import MessageUI

struct FeedbackView: View {
    @ObservedObject var score:Score
    @ObservedObject var studentFeedback:StudentFeedback
    
    var body: some View {
        HStack {
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
            Text("  ")
            if let feedbackExplanation = studentFeedback.feedbackExplanation {
                VStack {
                    Text(feedbackExplanation)
                        .defaultTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let feedbackNote = studentFeedback.feedbackNotes {
                VStack {
                    Text(feedbackNote)
                        .defaultTextStyle()
                }
            }
        }
    }
}

struct ScoreView: View {
    @ObservedObject var score:Score
    @ObservedObject var staffLayoutSize:StaffLayoutSize
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var dragOffset = CGSize.zero
    
    init(score:Score) {
        self.score = score
        self.staffLayoutSize = score.staffLayoutSize //StaffLayoutSize(lineSpacing: UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0)
        //self.staffLayoutSize.lineSpacing = 0.0
        //setOrientationLineSize(ctx: "ScoreView::init")
    }
    
    func getFrameHeight() -> Double {
        ///Score tells the staff how high to make itself. Child views of staff (all paths, moves, linesto sec) do not have
        ///inherent sizes that they can pass back up the parent staff view. So Score sets the sizes itself
        var height = 0.0
        //var lastStaff:Staff? = nil
        for staff in score.staffs {
            if !staff.isHidden {
                height += staffLayoutSize.lineSpacing
            }
            //lastStaff = staff
        }
        if score.barEditor != nil {
            height += staffLayoutSize.lineSpacing * 1.0
        }
        return height
    }
    
    func setOrientationLineSize(ctx:String, geometryWidth:Double) {
        //Absolutley no idea - the width reported here decreases in landscape mode so use height (which increases)
        //https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
        var lineSpacing:Double
//        if self.staffLayoutSize.lineSpacing == 0 {
//            //if UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                lineSpacing = 10.0
//            }
//            else {
//                if UIDevice.current.orientation == .portrait {
//                    lineSpacing = UIScreen.main.bounds.width / 64.0
//                }
//                else {
//                    lineSpacing = UIScreen.main.bounds.width / 128.0
//                }
//            }
//        }
//        else {
//            //make a small change only to force via Published a redraw of the staff views
//            lineSpacing = self.staffLayoutSize.lineSpacing
//            if UIDevice.current.orientation.isLandscape {
//                lineSpacing += 1
//            }
//            else {
//                lineSpacing -= 1
//            }
//        }
        //self.staffLayoutSize.setLineSpacing(lineSpacing) ????????? WHY 

        //lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
        lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : geometryWidth / 64.0
        
//        if UIDevice.current.orientation.isLandscape {
//            lineSpacing = lineSpacing / 1.5
//        }
//        if UIDevice.current.orientation.isLandscape {
//            print("\tLandscape", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        else {
//            print("\tPortrait", UIScreen.main.bounds, UIDevice.current.orientation.isFlat)
//        }
//        print("  \twidth::", UIScreen.main.bounds.width, "height:", UIScreen.main.bounds.height, "\tline spacing", ls)
        //UIGlobals.showDeviceOrientation()
//        print("👉 👉 =====> setOrientationLineSize",
//              "Score:", score.id.uuidString.suffix(4),
//              "Width:", geometryWidth,
//              "Context:", ctx,
//              "Portrait?", UIDevice.current.orientation.isPortrait, "lineSpacing", lineSpacing)
        self.staffLayoutSize.setLineSpacing(lineSpacing)
        //return lineSpacing
    }
    
    func getBarEditor() -> BarEditor? {
        var editor = score.barEditor
        if let editor = editor {
            editor.toggleState(0)
        }
        return editor
    }
    
    func logx() -> String {
        print("🤔 =====> ScoreView Body",
              "Score:", score.id.uuidString.suffix(4),
              //"Width:", geometryWidth,
              //"Portrait?", UIDevice.current.orientation.isPortrait
              "lineSpacing", self.staffLayoutSize.lineSpacing)

        return ""
    }
    
    var body: some View {
        VStack {
            if let feedback = score.studentFeedback {
                FeedbackView(score: score, studentFeedback: feedback)
            }
            
            VStack {
                ForEach(score.getStaff(), id: \.self.id) { staff in
                    if !staff.isHidden {
                        ZStack {
                            StaffView(score: score, staff: staff)
                                .frame(height: staffLayoutSize.getStaffHeight(score: score))
                                //.border(Color .red, width: 2)
                            
                            if getBarEditor() != nil {
                                BarEditorView(score: score)
                                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                            }
                        }
                    }
                }
            }
        }
        .background(
            ///This is required to get the size of the score view
            GeometryReader { geometry in
                Color.clear.onAppear {
                    self.setOrientationLineSize(ctx: "🤢.background", geometryWidth: geometry.size.width)
                    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                }
            }
        )
        
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .coordinateSpace(name: "ScoreView")
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .background(Settings.colorScore)
        //.border(Color .red, width: 4)
    }

}

