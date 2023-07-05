import SwiftUI
import CoreData
import AVFoundation
import Accelerate

struct LineChartView: View {
    let dataPoints: [Float] // Array of data points
    @State var title:String
    
    var body: some View {
        VStack {
            if dataPoints.count > 0 {
                Text(self.title)
                GeometryReader { geometry in
                    Path { path in
                        // Calculate the x and y coordinates for each data point
                        let xScale = geometry.size.width / CGFloat(dataPoints.count - 1)
                        let yScale = geometry.size.height / (CGFloat(dataPoints.max()!) / 0.5)
                        
                        // Start drawing the path at the first data point
                        path.move(to: CGPoint(x: 0, y: geometry.size.height - CGFloat(dataPoints[0]) * yScale))
                        
                        // Draw lines to connect the data points
                        for index in 1..<dataPoints.count {
                            let point = CGPoint(x: CGFloat(index) * xScale, y: geometry.size.height / 2.0 - CGFloat(dataPoints[index]) * yScale)
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2) // Customize the line appearance
                }
                //.aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
