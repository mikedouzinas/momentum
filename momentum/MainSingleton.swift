import Foundation

let useExperimentalAdaptiveQueueTTS = false

@Observable
class MainSingleton: AssistantMainObject {
    init() {
        self.initialize()
        Task.detached {
            // this is programming horror but michel is lazy and desperate.
            while self.textToSpeech == nil || self.assistant == nil {
                try! await Task.sleep(nanoseconds: 1_000_000)
            }
            self.newConversation()
        }
    }
    
    func setChatThread(_ thread: [ChatThreadItem]) {
        self.chatThread = thread
    }
    
    private var textToSpeechBufferedText = ""
    private var textToSpeech: TextToSpeech?
    
    private func speakText(_ text: String) async {
        await textToSpeech!.speakText(text, waitUntilOutput: false)
    }
    
    private func textToSpeechReset() async {
        await self.textToSpeech!.stop()
        self.textToSpeechBufferedText = ""
    }
    
    func newTextChunk(_ text: String) {
        if useExperimentalAdaptiveQueueTTS {
            Task.detached {
                await self.speakText(text)
            }
        } else {
            // Speak
            textToSpeechBufferedText.append(text)
            if let sentenceEnd = textToSpeechBufferedText.lastIndex(where: { character in
                character == "." || character == "!" || character == "?" || character == "。" || character == "！" || character == "？" || (textToSpeechBufferedText.count > 60 && character.isPunctuation)
            }) {
                let textToSpeechSpeak = String(self.textToSpeechBufferedText[...sentenceEnd])
                Task.detached {
                    await self.speakText(textToSpeechSpeak)
                }
                let newBuffer = String(self.textToSpeechBufferedText[self.textToSpeechBufferedText.index(after: sentenceEnd)...])
                if newBuffer.first?.isWhitespace == true {
                    self.textToSpeechBufferedText = String(newBuffer.dropFirst())
                } else {
                    self.textToSpeechBufferedText = newBuffer
                }
            }
        }
    }
    
    func endMessage() {
        let toSpeak = textToSpeechBufferedText
        self.textToSpeechBufferedText = ""
        Task.detached {
            await self.speakText(toSpeak)
        }
    }
    
    func updateActionProgress(id: String, tokenCount: Int) {
        print("Request update action progress for \(id), token count \(tokenCount)")
    }
    
    func updateActionText(id: String, text: String) {
        print("Request action text for \(id), new text \(text)")
    }
    
    private var assistant: Assistant? = nil
    
    let supportedActions: [Action] = [
        
    ]
    
    func initialize() {
        Task.detached {
            if self.textToSpeech == nil {
                if useExperimentalAdaptiveQueueTTS {
                    self.textToSpeech = AdaptiveQueueTTS()
                } else {
                    self.textToSpeech = OpenAITextToSpeech()
                }
                await self.textToSpeech!.prepare()
            }
            
            if self.assistant == nil {
                self.assistant = await OpenAIAssistant(actions: self.supportedActions)
                self.assistant!.registerMainObject(self)
                await self.assistant!.prepareForNewConversation()
            }
        }
    }
    
    func runUserCommand(_ text: String) {
        Task.detached {
            await self.assistant?.handleUserQuery(message: text)
        }
    }
    
    func newConversation() {
        Task.detached {
            async let _ = self.textToSpeechReset()
            async let _ = self.assistant!.prepareForNewConversation()
        }
    }
    
    private var currentCommand: String = ""
    var chatThread: [ChatThreadItem] = []
    
    func resetAssistant() async {
        async let _ = self.textToSpeechReset()
        self.assistant!.reset()
    }
}
