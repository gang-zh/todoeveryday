//
//  SoundManager.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/7/26.
//

import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        // This ensures the sound plays even if the system is in silent mode
        // For macOS, this is less critical but good practice
    }

    func playCompletionSound() {
        guard let soundURL = Bundle.main.url(forResource: "task-complete", withExtension: "mp3") else {
            print("Could not find task-complete.mp3 in bundle")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play completion sound: \(error)")
        }
    }
}
