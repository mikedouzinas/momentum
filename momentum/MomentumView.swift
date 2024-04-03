import SwiftUI
import AVFoundation
import Speech

struct MomentumView: View {
    @State private var isRecording = false
    @State private var audioText = "Hold button to begin speaking..."
    @State private var endAudioText = ""
    @ObservedObject private var speechRecognizer = SpeechRecognizer()
    @State private var animationAmount: CGFloat = 1
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                // Main Button centered in the middle
                Button(action: {
                    // Action intentionally left blank
                }) {
                    Image("logo") // change logo later
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .background(isRecording ? Color.gray : Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isRecording ? Color.red : Color.blue, lineWidth: 5)
                                .scaleEffect(animationAmount)
                                .opacity(Double(2 - animationAmount))
                                .animation(isRecording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: animationAmount)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    self.isRecording = pressing
                    if pressing {
                        
                        self.animationAmount = 2
                        endAudioText = "Release to finish."
                        
                        // self.startRecording()
                    } else {
                        endAudioText = ""
                        self.animationAmount = 1
                        // Stop recording
                        // self.stopRecording()
                    }
                }, perform: { })
                .foregroundColor(.white)
                .frame(width: geometry.size.width) // Force the button to occupy the full width of the GeometryReader
                // Positioned text above the center
                Text(audioText)
                    .frame(width: geometry.size.width * 0.8, height: 50)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    .padding(.top, 40)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading) // Ensure text is centered if it wraps
                
                Text("transcription")
                    .frame(width: geometry.size.width * 0.8, height: 200)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.bottom, 60)
                    .multilineTextAlignment(.leading)
                
                
                // Bottom three buttons
                HStack(spacing: 20) { // Add spacing between buttons
                    CircleTimerView()
                    Button(action: {}) {
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                    Button(action: {}) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                }
                .frame(width: geometry.size.width, height: 50, alignment: .center) // Ensure HStack is centered
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the GeometryReader takes up all available space
    }

    
    private func startRecording() {
        do {
            try speechRecognizer.startRecording()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
    }
}

struct CircleTimerView: View {
    var body: some View {
        // Implement the timer view
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.gray)
    }
}

struct MomentumView_Previews: PreviewProvider {
    static var previews: some View {
        MomentumView()
    }
}
