import Foundation

extension AdaptiveQueueTTS {
    struct TTSGenerationQueueItem {
        let text: String
        var atTime: Date
        let offsetRange: Range<Int>
    }
    
    // Provide thread-safe serial access to the queue
    actor TTSGenerationQueueState {
        private var queue: [TTSGenerationQueueItem] = [] // Holds the pending TTS generations
        private var queueID = "" // Unique identifier for the current queue
        private var queueText: String = "" // The total text to be transcribed. The sum of all texts in the queue should (somewhat; barring cleanup) equal this.
        private var queueTextStartIndexOffset: Int = 0 // Keeps track of the offset within the total buffer. The offset is used to provide unique "ID"s to everything in the queue. It's also used for indexing.
        
        func getID() -> String {
            return queueID
        }
        
        func getQueueTextAndOffset() -> (String, Int) {
            return (queueText, queueTextStartIndexOffset)
        }
        
        func pop() -> TTSGenerationQueueItem? {
            guard !isEmpty() else {
                return nil
            }
            
            let poppedGeneration = queue.removeLast()
            
            // remove the corresponding text from queue text
            precondition(poppedGeneration.offsetRange.lowerBound == queueTextStartIndexOffset)
            // compute the index
            let offset = poppedGeneration.offsetRange.upperBound - queueTextStartIndexOffset
            let reconstructedQueueTextIndex = queueText.index(queueText.startIndex, offsetBy: offset)
            // update the text
            queueText.removeSubrange(..<reconstructedQueueTextIndex)
            // update the start index offset
            queueTextStartIndexOffset += offset
            
            return poppedGeneration
        }
        
        func peek() -> TTSGenerationQueueItem? {
            return queue.first
        }
        
        func isEmpty() -> Bool {
            return queue.isEmpty
        }
        
        func updateQueue(_ newQueue: [TTSGenerationQueueItem]) {
            queue = newQueue
            queueID = UUID().uuidString
        }
        
        // This should be used for when new text is added to the queue.
        func updateQueueWithNewText(queue newQueue: [TTSGenerationQueueItem], appendingQueueText: String, queueTextStartIndexOffset newQueueTextStartIndexOffset: Int) {
            queue = newQueue
            queueID = UUID().uuidString
            queueText += appendingQueueText
            queueTextStartIndexOffset = newQueueTextStartIndexOffset
        }
        
        func reset() {
            updateQueue([])
            queueText = ""
            queueTextStartIndexOffset = 0
        }
        
        func debugDumpQueue() {
            print("----- TTSGenerationQueue debug dump -----")
            print("ID: \(queueID)")
            print("Queue: \(queue)")
            print("----- TTSGenerationQueue debug dump -----")
        }
        
        func debugValidateQueueInOrder() -> Bool {
            if queue.count <= 1 {
                return true
            }
            for index in 0..<queue.count - 1 {
                if queue[index].atTime > queue[index + 1].atTime {
                    return false
                }
            }
            return true
        }
    }
}
