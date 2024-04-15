import Foundation
import AVFoundation

func getAudioDataDuration(from data: Data) -> TimeInterval? {
    do {
        let audioPlayer = try AVAudioPlayer(data: data)
        return audioPlayer.duration // Duration in seconds
    } catch {
        print("Error creating audio player: \(error)")
        return nil
    }
}
