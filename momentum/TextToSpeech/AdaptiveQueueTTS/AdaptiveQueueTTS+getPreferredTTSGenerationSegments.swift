import Foundation

extension AdaptiveQueueTTS {
    /**
     Extracts preferred text segments from the given buffer for optimal TTS generation.
     
     This function analyzes the input buffer to identify the most suitable text segments for
     Text-to-Speech (TTS) generation. It prioritizes longer segments, such as complete paragraphs
     or multiple sentences, to provide the TTS model with more context and improve the quality of
     the generated speech.
     
     The function returns an array of tuples, where each tuple contains a preferred text segment
     for TTS generation and its corresponding end index in the original buffer. The text segments
     are ordered based on their suitability for TTS generation, with the most preferred segment
     appearing first in the array.
     
     The system should iterate through the returned array in order, starting with the first element,
     to find the most suitable text segment that fits within the available time constraints. Longer
     segments are generally preferred as they provide more context to the TTS model, resulting in
     higher-quality speech output.
     
     If the most preferred segment cannot be generated within the available time, the system should
     move on to the next segment in the array until it finds a suitable segment that can be generated
     within the given constraints.
     
     - Parameter buffer: The input buffer containing the text to be analyzed and segmented.
     
     - Returns: An array of tuples, where each tuple contains a preferred text segment for TTS
     generation and its corresponding end index in the original buffer. The text segments
     are ordered based on their suitability for TTS generation, with the most preferred
     segment appearing first in the array.
     
     - Note: The function assumes that the buffer contains valid text with appropriate paragraph and
     sentence structures.
     */
    static func getPreferredTTSGenerationSegments(_ buffer: String) -> [(String, String.Index)] {
        let sentenceSeparatorsCharacterSet: CharacterSet = [".", "!", "?", "\n", "。", "！", "？"]
        let sentenceSeparatorsCharacterArray: [Character] = [".", "!", "?", "\n", "。", "！", "？"]
        let trimmedBuffer = removeLastIncompleteSentence(buffer, separators: sentenceSeparatorsCharacterArray)
        print(trimmedBuffer)
        
        var preferredGenerations: [(String, String.Index)] = [] // Orders the strings to generate in the order of preference
        
        // First, prefer generating paragraphs
        var paragraphs: [(String, Range<String.Index>)] = []
        var currentIndex = trimmedBuffer.startIndex
        
        // Split the buffer into paragraphs
        while let range = trimmedBuffer[currentIndex...].range(of: "\n") {
            let paragraphRange = currentIndex..<range.upperBound
            let paragraph = String(trimmedBuffer[paragraphRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !paragraph.isEmpty {
                paragraphs.append((paragraph, paragraphRange))
            }
            currentIndex = range.upperBound
        }
        
        // Handle the remaining text after the last newline character
        if currentIndex < trimmedBuffer.endIndex {
            let paragraphRange = currentIndex..<trimmedBuffer.endIndex
            let paragraph = String(trimmedBuffer[paragraphRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !paragraph.isEmpty {
                paragraphs.append((paragraph, paragraphRange))
            }
        }
        
        // Add paragraphs to the preferred generations in reverse order
        for i in (0..<paragraphs.count).reversed() {
            let substring = paragraphs[...i].map { $0.0 }.joined(separator: "\n")
            let endIndex = paragraphs[i].1.upperBound
            preferredGenerations.append((substring, endIndex))
        }
        
        // If paragraphs cannot be added, prefer generating sentences
        guard let targetParagraph = paragraphs.first else {
            return preferredGenerations
        }
        let targetParagraphText = targetParagraph.0
        let targetParagraphRange = targetParagraph.1
        
        var sentences: [(String, Range<String.Index>)] = []
        currentIndex = targetParagraphText.startIndex
        
        // Split the target paragraph into sentences
        while let range = targetParagraphText[currentIndex...].rangeOfCharacter(from: sentenceSeparatorsCharacterSet) {
            let sentenceRange = currentIndex..<range.upperBound
            let sentence = String(targetParagraphText[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                let startIndex = trimmedBuffer.index(targetParagraphRange.lowerBound, offsetBy: targetParagraphText.distance(from: targetParagraphText.startIndex, to: sentenceRange.lowerBound))
                let endIndex = trimmedBuffer.index(targetParagraphRange.lowerBound, offsetBy: targetParagraphText.distance(from: targetParagraphText.startIndex, to: sentenceRange.upperBound))
                sentences.append((sentence, startIndex..<endIndex))
            }
            currentIndex = range.upperBound
        }
        
        // Handle the remaining text after the last sentence separator
        if currentIndex < targetParagraphText.endIndex {
            let sentenceRange = currentIndex..<targetParagraphText.endIndex
            let sentence = String(targetParagraphText[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                let startIndex = trimmedBuffer.index(targetParagraphRange.lowerBound, offsetBy: targetParagraphText.distance(from: targetParagraphText.startIndex, to: sentenceRange.lowerBound))
                let endIndex = trimmedBuffer.index(targetParagraphRange.lowerBound, offsetBy: targetParagraphText.distance(from: targetParagraphText.startIndex, to: sentenceRange.upperBound))
                sentences.append((sentence, startIndex..<endIndex))
            }
        }
        
        // Add sentences to the preferred generations in reverse order
        for i in (0..<(sentences.count - 1)).reversed() {
            let substring = sentences[...i].map { $0.0 }.joined(separator: " ")
            let endIndex = sentences[i].1.upperBound
            preferredGenerations.append((substring, endIndex))
        }
        
        return preferredGenerations
    }
}
