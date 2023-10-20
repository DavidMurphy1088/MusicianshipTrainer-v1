import SwiftUI
import Foundation

struct FlyingImageView: View {
    @State var answer:Answer
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    @State var yPos = 0.0
    @State var loop = 0
    let imageSize:CGFloat = 160.0
    let totalDuration = 15.0
    let delta = 100.0
    @State var rotation = 0.0
    @State var opacity = 1.0
    @State var imageNumber = 0
    
    func imageName() -> String {
        return "answer_animate_" + String(self.imageNumber)
    }
    
    var body: some View {
        ZStack {
            Image(imageName())
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(.blue)
                .opacity(opacity * 1.5)
                .rotationEffect(Angle(degrees: rotation))
                .position(position)
        }
        .onAppear {
            self.imageNumber = Int.random(in: 0...6)
            DispatchQueue.global(qos: .background).async {
                sleep(1)
                if !answer.correct {
                    withAnimation(Animation.linear(duration: 1.0)) { //}.repeatForever(autoreverses: false)) {
                        rotation = -90.0
                    }
                }
                animateRandomly()
            }
        }
    }
    
    func animateRandomly() {
        let loops = 4
        for _ in 0..<loops {
            var randomX = 0.0
            if answer.correct {
                yPos -= delta //CGFloat.random(in: imageSize/2 ... UIScreen.main.bounds.height - imageSize/2)
                randomX = CGFloat.random(in: imageSize * -1 ... imageSize * 2)
            }
            else {
                randomX = CGFloat.random(in: imageSize * -4 ... imageSize * 4)
                yPos += delta / 4.0
            }
            
            withAnimation(Animation.linear(duration: totalDuration / Double(loops))) { //}.repeatForever(autoreverses: false)) {
                opacity = 0.0
                position = CGPoint(x: UIScreen.main.bounds.width / 2 + randomX, y: UIScreen.main.bounds.height / 2 + yPos)
                //rotation = rotation * Double.random(in: 0...0.2)
                if self.answer.correct {
                    rotation = rotation + Double(Int.random(in: 0...10))
                }
                else {
                    rotation = rotation + 45.0
                }
            }
        }
    }
}
