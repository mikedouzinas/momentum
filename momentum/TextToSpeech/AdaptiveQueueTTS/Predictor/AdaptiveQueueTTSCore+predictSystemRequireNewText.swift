import Foundation

fileprivate let DEBUG_OUTPUT = true

extension AdaptiveQueueTTS {
    /// Predicts the time when the system will run out of audio files to play and thus require new text to be generated.
    func predictSystemRequireNewTextTime() async -> Date {
        // get how much time is remaining in the current playing
        // for all the existing audio files, get their length
        // for all the pending generations, predict their length
        // The system requires new text when the currently playing audio stops playing, existing audio files run out, and playback from pending generations also run out.
        
        async let currentlyPlayingStopTime = self.audioPlaybackManager.getCurrentlyPlayingStopTime()
        
        let generations = await self.ttsGenerationManager.getGenerationArray()
        
        var totalDuration: Double = 0.0
        
        await withTaskGroup(of: (Array<AdaptiveQueueTTS.TTSGeneration>.Index, Double).self) { group in
            for (index, generation) in generations.enumerated() {
                group.addTask {
                    if let duration = generation.duration {
                        // Generation has already completed.
                        return (index, duration)
                    } else {
                        let predictedDuration = max(await self.ttsAudioDurationPredictor.getConservativeLowPrediction(Double(generation.forText.count)), 0)
                        return (index, predictedDuration)
                    }
                }
            }
            
            for await (index, duration) in group {
                totalDuration += duration
            }
        }
        
        return ((await currentlyPlayingStopTime) ?? .now) + totalDuration
    }
}
