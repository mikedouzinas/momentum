import Foundation

protocol TTSEngine {
    func synthesizeSpeech(_ text: String) async throws -> Data
}
