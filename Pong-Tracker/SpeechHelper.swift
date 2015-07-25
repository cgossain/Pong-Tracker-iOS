//
//  SpeechHelper.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-07-14.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import AVFoundation

class SpeechHelper {
    
    static let sharedSpeechHelper = SpeechHelper()
    
    var speechRate = 0.0 {
        didSet {
            // validation
            if speechRate < 0 {
                speechRate = 0.0
            }
            else if speechRate > 1 {
                speechRate = 1.0
            }
        }
    }
    
    // A number between 0 to 1, 0 being the minimum rate and 1 being the maximum rate
    
    lazy var speechSynthesizer: AVSpeechSynthesizer = {
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.pauseSpeakingAtBoundary(.Word)
            return synthesizer
        }()
    
    init() {
        self.speechRate = 0.05 // 5% of maximum speed
    }
    
    // MARK: - Helpers
    
    func convertedSpeechRate() -> Float {
        var min = AVSpeechUtteranceMinimumSpeechRate
        var range = AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate
        var multiplier = Float(self.speechRate)
        return multiplier * range + min
    }
    
    func nameFromTeam(team: Team) -> String {
        var name = String()
        
        if let firstName = team.playerOne.firstName {
            name += firstName
        }
        
        if let lastName = team.playerOne.lastName {
            name += lastName
        }
        
        return name
    }
    
    func utterString(string: String) {
        // wrap the string into an utterance object
        let utterance = AVSpeechUtterance(string: string)
        utterance.rate = self.convertedSpeechRate()
//        utterance.pitchMultiplier = 0.5
        
        // speak the utterance
        self.speechSynthesizer.speakUtterance(utterance);
    }
    
    // MARK: - Utterances (Game State)
    
    func utterServingTeam(team: Team) {
        let string = self.nameFromTeam(team) + " to serve"
        
        // speak the string
        self.utterString(string);
    }
    
    func utterWinningTeam(team: Team) {
        let string = self.nameFromTeam(team) + " won the game"
        
        // speak the string
        self.utterString(string);
    }
    
    func utterMatchPointTeam(team: Team) {
        let string = self.nameFromTeam(team) + " has game point"
        
        // speak the string
        self.utterString(string);
    }
    
    // MARK: - Utterances (Insults)
    
    func insultTeam(team: Team) {
        let string = self.nameFromTeam(team) + " where did you learn to play ping pong? That was terrible."//", you should stick to you day job."
        
        // speak the string
        self.utterString(string);
    }
    
}