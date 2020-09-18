//
//  File.swift
//  
//
//  Created by Maarten Engels on 18/09/2020.
//

import Foundation
import Vapor

struct Player: Content {
    
    let id: UUID
    let name: String
    
    private(set) var actionPoints = 10
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
    
    func update() -> Player {
        var updatedPlayer = self
        
        updatedPlayer.actionPoints += 1
        updatedPlayer.actionPoints = min(PLAYER_MAX_ACTION_POINTS, updatedPlayer.actionPoints)
        
        return updatedPlayer
    }
    
}
