import Foundation
import Combine

// Goals of the Text-to-Speech (TTS) method:
// - Achieve low latency
// - Eliminate stutters
// - Minimize the number of API generation calls
// - Maximize quality by generating at sentence and paragraph boundaries when possible

// IMPORTANT: The code expects the generations to have monotonically increasing API call times.

class AdaptiveQueueTTS: TextToSpeech {
    let ttsEngine: TTSEngine = OpenAITTSEngine()
    
    init() {
        let hasNewAudioDataSignalSender = PassthroughSubject<Void, Never>()
        self.ttsGenerationManager = .init(hasNewAudioDataSignalSender: hasNewAudioDataSignalSender)
        self.audioPlaybackManager = .init(hasNewAudioDataSignalSender: hasNewAudioDataSignalSender, generationManager: self.ttsGenerationManager)
    }
    
    let ttsAPIResponseTimePredictor = StatefulConfigurableWeightedRegressionPredictor(
        config: .apiResponseTimePredictorConfiguration(),
        storageKey: "textLengthToTTSAPIResponseTime"
    )
    let ttsAudioDurationPredictor = StatefulConfigurableWeightedRegressionPredictor(
        config: .audioDurationPredictorConfiguration(),
        storageKey: "textLengthToTTSAudioDuration"
    )
    
    func stop() async {
        async let _ = ttsGenerationQueueState.reset()
        async let _ = audioPlaybackManager.prepare()
        async let _ = ttsGenerationManager.clear()
    }
    
    func prepare() async {
        await audioPlaybackManager.prepare()
        try! await audioPlaybackManager.startPlayback()
    }
    
    private var processQueuedGenerationTask: Task<Void, Never>?
    private func runProcessQueuedGeneration(queueID: String) {
        if let previousTask = processQueuedGenerationTask {
            previousTask.cancel()
        }
        
        processQueuedGenerationTask = Task.detached(
            priority: .high,
            operation: {
                await self.processQueuedGeneration(queueID: await self.ttsGenerationQueueState.getID())
            }
        )
        
    }
    
    let ttsGenerationQueueState = TTSGenerationQueueState()
    let ttsGenerationManager: TTSGenerationManager!
    let audioPlaybackManager: AudioPlaybackManager!
    
    func speakText(_ newText: String, waitUntilOutput: Bool) async {
        let (queueText, queueTextStartIndexOffset) = await ttsGenerationQueueState.getQueueTextAndOffset()
        let totalQueueText = queueText + newText

        // Process the total buffer and add elements to the queue
        let newQueue = await computeQueueForText(text: totalQueueText, textStartIndexOffset: queueTextStartIndexOffset)
        print(newQueue)
        
        await ttsGenerationQueueState.updateQueueWithNewText(queue: newQueue, appendingQueueText: newText, queueTextStartIndexOffset: queueTextStartIndexOffset)
        
        // run the queue
        runProcessQueuedGeneration(queueID: await ttsGenerationQueueState.getID())
    }
}
