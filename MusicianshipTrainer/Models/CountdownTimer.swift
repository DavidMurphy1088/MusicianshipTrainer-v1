import SwiftUI
import Combine

struct CountdownTimerView: View {
    @State private var timeRemaining = 30
    @State private var timer: AnyCancellable?
    @State private var isActive = false

    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                if self.isActive {
                    self.timer?.cancel()
                    self.timer = nil
                } else {
                    if timeRemaining == 0 {
                        timeRemaining = 30
                    }
                    self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                        .sink { _ in
                            if self.timeRemaining > 0 {
                                self.timeRemaining -= 1
                            } else {
                                self.timer?.cancel()
                                self.isActive = false
                            }
                        }
                }
                self.isActive.toggle()
            }) {
                Text(isActive ? "Pause Timer" : "Start Timer")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            CircularProgressView(progress: CGFloat(timeRemaining) / 30.0, timeRemaining: timeRemaining)
                .frame(width: 100, height: 100)
                .padding(20)
        }
    }
}

struct CircularProgressView: View {
    var progress: CGFloat
    var timeRemaining: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5)
                .opacity(0.3)
                .foregroundColor(Color.blue)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .aspectRatio(contentMode: .fit)

            Text("\(timeRemaining) secs")
                //.font(.footnote)
        }
    }
}

