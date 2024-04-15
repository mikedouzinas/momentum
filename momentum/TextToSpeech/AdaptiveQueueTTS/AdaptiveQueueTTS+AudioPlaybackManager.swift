import Foundation
import AVFAudio
import Combine

extension AdaptiveQueueTTS {
    /// The `AudioPlaybackManager` is responsible for managing audio playback in the `AdaptiveQueueTTS` system.
    /// It handles searching for available audio data, playing audio, and waiting for new audio data to arrive.
    actor AudioPlaybackManager {
        /// Represents the different states of audio playback.
        enum AudioPlaybackState {
            case stop
            case searching
            case playing
            case waitingForData
        }
        
        /// An error indicating that audio playback is already in progress.
        struct AudioPlaybackAlreadyPlayingError: Error { }
        
        /// The audio player used for playback.
        private var audioPlayer: AudioPlayer = .init()
        
        /// The current state of audio playback.
        private var audioPlaybackState: AudioPlaybackState = .stop
        
        /// A signal that indicates when new audio data is available.
        private var hasNewAudioDataSignalSender: PassthroughSubject<Void, Never>
        
        /// The subscription to the `hasNewAudioDataSignal`.
        private var hasNewAudioDataSignalSubscription: AnyCancellable! = nil
        
        /// The current playback item being played.
        private var currentPlaybackItem: TTSGeneration? = nil
        
        /// The start time of the current playback item.
        private var currentPlaybackItemStartPlaybackTime: Date? = nil
        
        /// The manager responsible for generating TTS audio data.
        private var generationManager: TTSGenerationManager
        
        /// The offset for the next playback item.
        private var nextPlaybackOffset: Int? = nil
        
        /// Initializes a new instance of `AudioPlaybackManager`.
        ///
        /// - Parameters:
        ///   - hasNewAudioDataSignal: A signal that indicates when new audio data is available.
        ///   - generationManager: The manager responsible for generating TTS audio data.
        init(hasNewAudioDataSignalSender: PassthroughSubject<Void, Never>, generationManager: TTSGenerationManager) {
            self.hasNewAudioDataSignalSender = hasNewAudioDataSignalSender
            self.generationManager = generationManager
            
            Task.detached {
                await self.setupSubscription()
            }
        }
        
        /// Sets up the subscription to the `hasNewAudioDataSignal`.
        private func setupSubscription() {
            self.hasNewAudioDataSignalSubscription = hasNewAudioDataSignalSender
                .sink {
                    Task.detached {
                        await self.triggerPlaybackForNewAudioDataSignal()
                    }
                }
        }
        
        /// Prepares the audio player for playback.
        func prepare() {
            stop()
            audioPlayer.prepare()
        }
        
        /// Starts audio playback.
        ///
        /// - Throws: `AudioPlaybackAlreadyPlayingError` if audio playback is already in progress.
        func startPlayback() async throws {
            print("[AudioPlaybackManager] startPlayback() called - Playback state \(audioPlaybackState)")
            guard audioPlaybackState == .stop else {
                throw AudioPlaybackAlreadyPlayingError()
            }
            
            nextPlaybackOffset = nil
            await self.startPlaybackInternal()
        }
        
        /// Starts audio playback internally.
        private func startPlaybackInternal() async {
            print("[AudioPlaybackManager] startPlaybackInternal() called - Playback state \(audioPlaybackState)")
            audioPlaybackState = .searching
            
            if let nextPlaybackOffset = nextPlaybackOffset {
                await generationManager.seekToOffset(nextPlaybackOffset)
            }
            
            // Search for something in the queue that has already completed processing from the API.
            // If not, mark as waiting for data and then return.
            guard (await generationManager.mostRecentGenerationHasCompleted()) == true else {
                audioPlaybackState = .waitingForData
                return
            }
            
            guard let generation = await generationManager.popMostRecentGeneration() else {
                assertionFailure("Popped generation nil")
                audioPlaybackState = .waitingForData
                return
            }
            
            // Set the playback offset
            nextPlaybackOffset = generation.offsetRange.upperBound
            guard let data = generation.audioData, let duration = generation.duration else {
                assertionFailure("Popped generation not finished or missing duration data (\(generation))")
                audioPlaybackState = .waitingForData
                return
            }
            
            audioPlaybackState = .playing
            do {
                try audioPlayer.interruptAndPlay(data)
            } catch {
                print("Unexpected error while performing playback: \(error)")
            }
            
            try! await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000.0))
            audioPlaybackState = .searching
            await startPlaybackInternal()
        }
        
        /// Triggers playback when a new audio data signal is received.
        private func triggerPlaybackForNewAudioDataSignal() async {
            print("[AudioPlaybackManager] triggerPlaybackForNewAudioDataSignal() called - Playback state \(audioPlaybackState)")
            guard audioPlaybackState == .waitingForData else {
                return
            }
            
            await self.startPlaybackInternal()
        }
        
        /// Stops audio playback.
        func stop() {
            print("[AudioPlaybackManager] stop() called - Playback state \(audioPlaybackState)")
            audioPlayer.stop()
            audioPlaybackState = .stop
            currentPlaybackItem = nil
            currentPlaybackItemStartPlaybackTime = nil
            nextPlaybackOffset = nil
        }
        
        func getCurrentlyPlayingStopTime() -> Date? {
            guard let currentPlaybackItemStartPlaybackTime = currentPlaybackItemStartPlaybackTime, let currentPlaybackItem = currentPlaybackItem, let duration = currentPlaybackItem.duration else {
                return nil
            }
            
            return currentPlaybackItemStartPlaybackTime + duration
        }
    }
}
