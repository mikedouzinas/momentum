import Foundation

let DEBUG_ENSURE_QUEUE_IS_IN_ORDER = true

extension AdaptiveQueueTTS {
    private func matchesQueue(id: String) async -> Bool {
        if id == (await ttsGenerationQueueState.getID()) {
            return true
        } else {
            return false
        }
    }
    
    func processQueuedGeneration(queueID: String) async {
        // sleep until the first task. Constantly check for queueID and for whether Task is cancelled.
        guard await matchesQueue(id: queueID) else {
            return
        }
        
        if DEBUG_ENSURE_QUEUE_IS_IN_ORDER {
            if !(await ttsGenerationQueueState.debugValidateQueueInOrder()) {
                print("Queue not in order!")
                await ttsGenerationQueueState.debugDumpQueue()
            }
        }
        
        guard let firstTask = (await ttsGenerationQueueState.peek()) else {
            return
        }
        
        try? await sleepUntil(firstTask.atTime)
        
        guard await matchesQueue(id: queueID) else {
            return
        }
        
        guard !Task.isCancelled else {
            return
        }
        
        guard let taskToExecute = await ttsGenerationQueueState.pop() else {
            assertionFailure("Unexpected no task to execute despite matching queue ID")
            return
        }
        
        // perform the API call on a detached task to prevent it from blocking further queue generation and to prevent it from being cancelled (which may lead to unknown results), even when the parent task is cancelled.
        Task.detached {
            // measure time taken for future prediction
            let startTime = DispatchTime.now()
            // report generation
            let generationID = await self.ttsGenerationManager.reportSubmitToAPI(text: taskToExecute.text, offsetRange: taskToExecute.offsetRange)
            // perform API call
            let ttsAudioData = try! await self.ttsEngine.synthesizeSpeech(taskToExecute.text)
            let endTime = DispatchTime.now()
            
            let apiResponseTimeSeconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            async let _ = self.ttsAPIResponseTimePredictor.addDataPoint(Double(taskToExecute.text.count), apiResponseTimeSeconds)
            
            // Compute the duration
            let duration = getAudioDataDuration(from: ttsAudioData)
            if let duration = duration {
                async let _ = self.ttsAudioDurationPredictor.addDataPoint(Double(taskToExecute.text.count), duration)
            } else {
                print("[WARNING] Could not determine audio duration!")
            }
            
            // Report generation
            async let _ = self.ttsGenerationManager.reportResultsReceived(id: generationID, audioData: ttsAudioData, duration: duration ?? 0)
        }
        
        // recursively perform further queue generation
        await processQueuedGeneration(queueID: queueID)
    }
}
