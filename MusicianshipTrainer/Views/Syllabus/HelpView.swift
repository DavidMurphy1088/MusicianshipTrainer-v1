import SwiftUI
import CoreData
import MessageUI

struct HelpView: View {
    var helpInfo:String
    let lightTealColor = UIColor(red: 0.4, green: 0.9, blue: 0.9, alpha: 1.0)

    var body: some View {
        VStack {
            Text("Help").font(.title)
            Text(helpInfo).padding()
            //Spacer()
        }
        .background(Color(lightTealColor))
        .padding()
        .cornerRadius(6)
        //.shadow(radius: 5)
    }
}
