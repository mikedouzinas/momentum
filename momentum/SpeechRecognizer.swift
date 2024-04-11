import Foundation
import AVFoundation
import Speech

class SpeechRecognizer: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSession = AVAudioSession.sharedInstance()
    
    init() {
        speechRecognizer = SFSpeechRecognizer()
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        stopRecording() // Ensure we're starting from a clean state
        
        // Check for speech recognition availability
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(NSError(domain: "SFSpeechRecognizerErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition is not available."])))
            return
        }
        
        // Request permissions
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    do {
                        try self.startAudioEngine(completion: completion)
                    } catch {
                        completion(.failure(error))
                    }
                default:
                    completion(.failure(NSError(domain: "SFSpeechRecognizerErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition permission was not granted."])))
                }
            }
        }
    }
    
    private func startAudioEngine(completion: @escaping (Result<String, Error>) -> Void) throws {
        // Reset the audio engine and recognition task to ensure a clean state
        audioEngine.stop()
        audioEngine.reset()
        recognitionTask?.cancel()
        recognitionRequest = nil

        // Setup the audio session as before
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // This will update for each piece of recognized speech
                isFinal = result.isFinal
                DispatchQueue.main.async {
                    // Ensure UI updates happen on the main thread
                    completion(.success(result.bestTranscription.formattedString))
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // Handle any final actions if needed
            }
        }

        // Configure and start the audio engine
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.removeTap(onBus: 0) // Make sure to remove any existing tap
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    
    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0) // Ensure any existing tap is removed
        audioEngine.stop()
        recognitionRequest?.endAudio()
        try? audioSession.setActive(false)
        recognitionTask = nil // End any existing recognition tasks
        recognitionRequest = nil // Dispose of the existing request
    }
}
