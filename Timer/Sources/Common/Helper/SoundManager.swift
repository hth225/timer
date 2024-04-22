//
//  SoundManager.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation
import AVKit

class SoundManager: ObservableObject {
    static let instance = SoundManager()
    
    var player: AVAudioPlayer?
    
    func playTimerEnd() throws {
        guard let url = Bundle.main.url(forResource: "small-hand-bell-ding-sound-effect", withExtension: ".mp3") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.2
            player?.play()
        } catch(let error) {
            throw error
        }
    }
}
