import Foundation
import AVFoundation

extension AdaptiveQueueTTS {
    /// A simple class to handle audio playback.
    class AudioPlayer {
        var audioPlayer: AVAudioPlayer?
        func prepare() {
            audioPlayer?.prepareToPlay()
        }

        /// Play the audio data. Note that this will interrupt any currently playing audio.
        func interruptAndPlay(_ audio: Data) throws {
            audioPlayer?.stop()
            audioPlayer = try? AVAudioPlayer(data: audio)
            audioPlayer?.play()
        }

        func stop() {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
}
