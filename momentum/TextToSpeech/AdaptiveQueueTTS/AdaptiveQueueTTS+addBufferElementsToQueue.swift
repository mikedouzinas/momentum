import Foundation

extension AdaptiveQueueTTS {
    func estimateAPIComputeTime(for generation: String) async -> TimeInterval {
        return max(await ttsAPIResponseTimePredictor.getConservativeHighPrediction(Double(generation.count)), 0)
    }
    
    // Function to process the buffer and add elements to the queue for a new buffer
    func computeQueueForText(text: String, textStartIndexOffset: Int) async -> [TTSGenerationQueueItem] {
        var queue: [TTSGenerationQueueItem] = []
        
        // Get the time when the system runs out of already generated text-to-speech portions
        let systemNeedsNewTextDate: Date = await predictSystemRequireNewTextTime()
        
        await computeQueueForBuffer(text: text, textStartIndexOffset: textStartIndexOffset, systemNeedsNewTextDate: systemNeedsNewTextDate, queue: &queue)
        return queue
    }
    
    func computeQueueForBuffer(text: String, textStartIndexOffset: Int, systemNeedsNewTextDate: Date, queue: inout [TTSGenerationQueueItem]) async {
        // Compute the preferred generations based on paragraphs and sentences
        let preferredGenerations = AdaptiveQueueTTS.getPreferredTTSGenerationSegments(text)
        
        if preferredGenerations.isEmpty {
            return
        }

        // Iterate over the preferred generations
        for (index, (generation, generationRangeUpperBound)) in preferredGenerations.enumerated() {
            // Compute the estimated time required for API to generate the text
            let estimatedComputeTime = await estimateAPIComputeTime(for: generation) // Make a conservative estimate

            // Calculate the estimated completion date for the generation
            let estimatedComputeCompletionDate = Date() + estimatedComputeTime

            // Check if the generation can be completed within the available time window
            // Alternatively, if the generation is the last one, add it to the queue as a fallback
            if estimatedComputeCompletionDate < systemNeedsNewTextDate || index == preferredGenerations.count - 1 {
                // Calculate the offset range for the generation within the buffer
                let integerOffsetRange = textStartIndexOffset..<textStartIndexOffset + text.distance(from: text.startIndex, to: generationRangeUpperBound)

                // Add the generation to the queue with the appropriate timing and offset range
                queue.append(.init(text: generation, atTime: systemNeedsNewTextDate - estimatedComputeTime, offsetRange: integerOffsetRange))

                // Compute the new buffer by excluding the already queued generation
                let newText = String(text[generationRangeUpperBound...])
                let newTextGenerationDurationEstimate = await self.ttsAudioDurationPredictor.getConservativeLowPrediction(Double(newText.count)) * 0.8

                // Compute the new buffer offset
                let newTextStartIndexOffset = integerOffsetRange.upperBound

                // Recursively call the function with the new buffer and new buffer offset
                await computeQueueForBuffer(text: newText, textStartIndexOffset: newTextStartIndexOffset, systemNeedsNewTextDate: systemNeedsNewTextDate + newTextGenerationDurationEstimate, queue: &queue)
                return
            }
        }
    }
}
