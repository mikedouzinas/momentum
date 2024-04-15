import Foundation
import AVFoundation
import SwiftOpenAI

class OpenAITTSEngine: TTSEngine {
    let service: OpenAIService
    
    init() {
        let apiKey = OpenAIAPIKey
        self.service = OpenAIServiceFactory.service(apiKey: apiKey)
    }
    
    func synthesizeSpeech(_ text: String) async throws -> Data {
        print("Called to synthesize \(text)")
        // would be an intruiging idea to integrate exponential backoff here.
        let parameters = AudioSpeechParameters(model: .tts1, input: text, voice: .nova, speed: 1.3)
        let audioObjectData: Data = try! await service.createSpeech(parameters: parameters).output
        return audioObjectData
    }
}
