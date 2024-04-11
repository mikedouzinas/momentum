import SwiftUI
import AVFoundation
import Speech

struct MomentumView: View {
    @State private var isRecording = false
    @State private var audioText = "Tap button to begin speaking..."
    @State private var endAudioText = ""
    @State private var transcribedText: String = ""
    @ObservedObject private var speechRecognizer = SpeechRecognizer()
    @State private var animationAmount: CGFloat = 1
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Positioned text above the center
                Spacer()
                ScrollView {
                    Text(transcribedText)
                        .multilineTextAlignment(.leading)
                        .frame(width: geometry.size.width * 0.8, alignment: .leading)
                        .padding([.leading], 20.0) // Add padding to the left and rights
                        .padding(.top, 10) // Optional: add padding to the top to ensure consistency
                }
                .frame(width: geometry.size.width * 0.8, height: 350)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .padding(.bottom, 60)
                
                // Main Button centered in the middle
                Button(action: toggleRecording) {
                    Image("logo") // change logo later
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
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
                .animation(.easeInOut, value: isRecording)
                .frame(width: geometry.size.width) // Force the button to occupy the full width of the GeometryReader
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the GeometryReader takes up all available space
    }

    private func toggleRecording() {
        isRecording.toggle() // Toggle the recording state
        
        if isRecording {
            // Update UI for recording state
            audioText = "Recording... Tap to stop."
            startRecording()
        } else {
            // Update UI for not recording state
            audioText = "Tap button to begin speaking..."
            stopRecording()
        }
    }
    
    func startRecording() {
        speechRecognizer.startRecording { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    self.transcribedText = text
                case .failure(let error):
                    self.transcribedText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
    }
    private func proceed() {
        print("proceeding!")
    }
}

struct CircleTimerView: View {
    @State private var countdown = 3
    var onFinish: () -> Void // This closure will be called when the countdown finishes
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            
            Text("\(countdown)")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .onAppear {
            startCountdown()
        }
    }
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate() // Stop the timer
                onFinish() // Call the function passed as a closure
            }
        }
    }
}

struct MomentumView_Previews: PreviewProvider {
    static var previews: some View {
        MomentumView()
    }
}
