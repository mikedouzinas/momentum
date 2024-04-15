protocol TextToSpeech {
    func stop() async
    func prepare() async
    func speakText(_ str: String, waitUntilOutput: Bool) async -> Void
}

