import Foundation
import HeapModule
import Combine

extension AdaptiveQueueTTS {
    class TTSGeneration: Comparable, Identifiable {
        internal init(id: String, forText: String, audioData: Data? = nil, duration: Double? = nil, offsetRange: Range<Int>) {
            self.id = id
            self.forText = forText
            self.audioData = audioData
            self.duration = duration
            self.offsetRange = offsetRange
        }
        
        static func < (lhs: AdaptiveQueueTTS.TTSGeneration, rhs: AdaptiveQueueTTS.TTSGeneration) -> Bool {
            // put earlier TTS results first for the playback engine to pick out
            if lhs.offsetRange.lowerBound != rhs.offsetRange.lowerBound {
                return lhs.offsetRange.lowerBound < rhs.offsetRange.lowerBound
            }
            
            // in the case of identical `lowerBound` (shouldn't be very likely, but concurrency leads to unpredictable shit) prefer already generated results
            if (lhs.audioData == nil) != (rhs.audioData == nil) {
                if lhs.audioData == nil {
                    // prefer rhs
                    return false
                } else {
                    return true
                }
            }
            
            // otherwise prefer longer TTS results (generally higher-quality)
            return lhs.forText.count > rhs.forText.count
        }
        
        static func == (lhs: AdaptiveQueueTTS.TTSGeneration, rhs: AdaptiveQueueTTS.TTSGeneration) -> Bool {
            return lhs.id == rhs.id
        }
        
        let id: String
        let forText: String
        var audioData: Data?
        var duration: Double?
        let offsetRange: Range<Int>
    }
    
    actor TTSGenerationManager {
        private var ttsGenerationHeap: Heap<TTSGeneration> = .init()
        private var idToTTSGenerationMap: [String: TTSGeneration] = [:]
        private var hasNewAudioDataSignalSender: PassthroughSubject<Void, Never>
        
        init(hasNewAudioDataSignalSender: PassthroughSubject<Void, Never>) {
            self.hasNewAudioDataSignalSender = hasNewAudioDataSignalSender
        }
        
        func reportSubmitToAPI(text: String, offsetRange: Range<Int>) -> String {
            let id = UUID().uuidString
            let ttsGeneration: TTSGeneration = .init(id: id, forText: text, audioData: nil, duration: nil, offsetRange: offsetRange)
            
            ttsGenerationHeap.insert(ttsGeneration)
            // Record the TTSGeneration inside of a map so that the audio data and duration can be efficiently added to it later, even when it's inside of a heap.
            idToTTSGenerationMap[id] = ttsGeneration
            return id
        }
        
        func reportResultsReceived(id: String, audioData: Data, duration: Double) {
            guard let generation = idToTTSGenerationMap[id] else {
                return
            }
            
            hasNewAudioDataSignalSender.send()
            
            generation.audioData = audioData
            generation.duration = duration
        }
        
        func getGenerationArray() -> [TTSGeneration] {
            return ttsGenerationHeap.unordered
        }
        
        func clear() {
            ttsGenerationHeap = .init()
            idToTTSGenerationMap = [:]
        }
        
        func popMostRecentGeneration() -> TTSGeneration? {
            guard let generation = ttsGenerationHeap.popMin() else {
                return nil
            }
            // remove from the map
            idToTTSGenerationMap.removeValue(forKey: generation.id)
            
            return generation
        }
        
        func seekToOffset(_ offset: Int) {
            while ((ttsGenerationHeap.min?.offsetRange.lowerBound ?? offset + 1) < offset) {
                ttsGenerationHeap.popMin()
            }
        }
        
        func mostRecentGenerationHasCompleted() -> Bool? {
            guard let generation = ttsGenerationHeap.min else {
                return nil
            }
            
            return generation.audioData != nil
        }
        
        func isEmpty() -> Bool {
            return ttsGenerationHeap.isEmpty
        }
    }
}
