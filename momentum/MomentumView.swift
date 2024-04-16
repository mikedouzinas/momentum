import SwiftUI
import AVFoundation
import Speech

struct MomentumView: View {
    @State private var isRecording = false
    @State private var transcribedText: String = ""
    @ObservedObject private var speechRecognizer = SpeechRecognizer()
    @State private var animationAmount: CGFloat = 1
    
    @State var mainSingleton: MainSingleton = .init()
    
    @State private var showLoading = false  // State to control the visibility of the loading view
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Positioned text above the center
                Spacer()
                ScrollView {
                    Text(transcribedText)
                        .multilineTextAlignment(.leading)
                        .frame(width: geometry.size.width * 0.8, alignment: .leading)
                        .padding([.leading], 20.0)
                        .padding(.top, 10)
                    
                    if showLoading {
                        LoadingView()
                            .frame(width: geometry.size.width * 0.8, height: 350)
                    }
                }
                .frame(width: geometry.size.width * 0.8, height: 350)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .padding(.bottom, 60)
                .allowsHitTesting(!showLoading) // Disable hit testing when loading view is visible

                // Main Button centered in the middle
                Button(action: toggleRecording) {
                    Image("logo") // Placeholder for actual logo
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    func startRecording() {
        transcribedText = ""
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
        mainSingleton.runUserCommand(transcribedText)
        showLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showLoading = false
        }
    }
}

struct MomentumView_Previews: PreviewProvider {
    static var previews: some View {
        MomentumView()
    }
}



struct LoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue) // Assuming the rectangle is black
                .opacity(0.95)
                .frame(width: 200, height: 200) // Makes the view square
                .cornerRadius(20) // Rounded corners
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white)) // White color for loader
                    .scaleEffect(1.5) // Make the loader slightly larger
                Text("Working...")
                    .foregroundColor(.white) // Text color white to contrast with black background
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
