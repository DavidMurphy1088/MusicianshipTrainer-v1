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

//struct ScoreSelectView: View {
//    @State private var dragOffset = CGSize.zero
//    @State private var isDragging = false
//    @State private var viewWidth = 0.0
//    @State private var barWidth = 200.0
//    @State private var offset = 0.0
//
//    var drag: some Gesture {
//        DragGesture()
//            .onChanged { _ in self.isDragging = true }
//            .onEnded { _ in self.isDragging = false }
//    }
//
//    func getOffset() -> CGFloat {
//        var x = self.viewWidth * 0.50 - self.barWidth / 2.0
//        x += self.offset
//        return x
//    }
//
//    var body: some View {
//        HStack {
//            Rectangle()
//                .fill(self.isDragging ? Color.red : Color.indigo)
//                .frame(width: barWidth, height: 20)
//                .cornerRadius(10)
//                .offset(x: getOffset(), y: 0)
//
//                .gesture(
//                    DragGesture()
//                        .onChanged { value in
//                            self.dragOffset = value.translation
//                            self.isDragging = true
//                            self.offset = value.location.x - value.startLocation.x
//                        }
//                        .onEnded { value in
//                            self.isDragging = false
//                        }
//                )
//
//            //        Circle()
//            //            .fill(self.isDragging ? Color.red : Color.blue)
//            //            .frame(width: 50, alignment: .center)
//            //            .gesture(drag)
//            //        }
//        }
//        .background(
//            GeometryReader { geometry in
//                Color.clear.onAppear {
//                    self.viewWidth = geometry.size.width
//                }
//            }
//        )
//
//    }
//}

struct ScoreView: View {
    @ObservedObject var score:Score
    @ObservedObject var staffLayoutSize:StaffLayoutSize
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var dragOffset = CGSize.zero
    
    init(score:Score) {
        self.score = score
        self.staffLayoutSize = StaffLayoutSize(lineSpacing: UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0)
        self.staffLayoutSize.lineSpacing = 0.0
        setOrientationLineSize(ctx: "ScoreView::init")
    }
    
    func getFrameHeight() -> Double {
        ///Score tells the staff how high to make itself. Child views of staff (all paths, moves, linesto sec) do not have
        ///inherent sizes that they can pass back up the parent staff view. So Score sets the sizes itself
        var height = 0.0
        var lastStaff:Staff? = nil
        for staff in score.staffs {
            if !staff.isHidden {
                height += staffLayoutSize.lineSpacing
            }
            lastStaff = staff
        }
        if score.barManager != nil {
            height += staffLayoutSize.lineSpacing * 1.0
        }
        return height
    }
    
    func setOrientationLineSize(ctx:String) {
        //Absolutley no idea - the width reported here decreases in landscape mode so use height (which increases)
        //https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
        var lineSpacing:Double
        if self.staffLayoutSize.lineSpacing == 0 {
            //if UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
            if UIDevice.current.userInterfaceIdiom == .phone {
                lineSpacing = 10.0
            }
            else {
                if UIDevice.current.orientation == .portrait {
                    lineSpacing = UIScreen.main.bounds.width / 64.0
                }
                else {
                    lineSpacing = UIScreen.main.bounds.width / 128.0
                }
            }
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
        //self.staffLayoutSize.setLineSpacing(lineSpacing) ????????? WHY 

        lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ?
                            10.0 : UIScreen.main.bounds.width / (score.noteSize == .small ? 64.0 : 48.0)
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
        //print("=====>>setOrientationLineSize", "Context", ctx, "Portrait?", UIDevice.current.orientation.isPortrait, "lineSpacing", lineSpacing)
        self.staffLayoutSize.setLineSpacing(lineSpacing)
    }
    
    var body: some View {
        VStack {
            if let feedback = score.studentFeedback {
                FeedbackView(score: score, studentFeedback: feedback)
            }
            
            //ZStack {
                VStack {
                    ForEach(score.getStaff(), id: \.self.id) { staff in
                        if !staff.isHidden {
                            ZStack {
                                StaffView(score: score, staff: staff, staffLayoutSize: staffLayoutSize)
                                    .frame(height: staffLayoutSize.getStaffHeight(score: score))
                                if let barManager = score.barManager {
                                    BarManagerView(score: score,
                                                   barManager: barManager, barLayoutPositions: score.barLayoutPositions,
                                                   lineSpacing: staffLayoutSize.lineSpacing)
                                                   
                                        .frame(height: staffLayoutSize.getStaffHeight(score: score))
                                }

                            }
                        }
                    }
                }
            //}
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
        .coordinateSpace(name: "ScoreView")
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .background(Settings.colorScore)
        //.border(Color .red, width: 4)
        //.frame(height: getFrameHeight())
    }

}

