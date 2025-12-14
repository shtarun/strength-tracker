import SwiftUI

struct RestTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var seconds: Int
    let defaultTime: Int

    @State private var timer: Timer?
    @State private var isRunning = true

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.headline)
                .padding(.top)

            // Timer display
            Text(formatTime(seconds))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(seconds <= 10 ? .orange : .primary)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(seconds) / CGFloat(defaultTime))
                    .stroke(
                        seconds <= 10 ? Color.orange : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: seconds)
            }
            .frame(width: 120, height: 120)

            // Controls
            HStack(spacing: 24) {
                Button {
                    seconds = max(0, seconds - 30)
                } label: {
                    Image(systemName: "gobackward.30")
                        .font(.title)
                }

                Button {
                    isRunning.toggle()
                    if isRunning {
                        startTimer()
                    } else {
                        timer?.invalidate()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }

                Button {
                    seconds += 30
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.title)
                }
            }

            Button("Skip Rest") {
                timer?.invalidate()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else {
                timer?.invalidate()
                // Could trigger haptic here
                dismiss()
            }
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    RestTimerSheet(seconds: .constant(180), defaultTime: 180)
}
