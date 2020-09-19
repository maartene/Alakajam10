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
    var ship: Ship
    var shipPoints = 3
    
    private(set) var actionPoints = 10
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.ship = Ship()
    }
    
    func update() -> Player {
        var updatedPlayer = self
        
        updatedPlayer.actionPoints += 1
        updatedPlayer.actionPoints = min(PLAYER_MAX_ACTION_POINTS, updatedPlayer.actionPoints)
        
        return updatedPlayer
    }
    
    func executeCommand(_ command: GameCommand) -> Player {
        var changedPlayer = self
        
        guard changedPlayer.actionPoints > 0 else {
            return self
        }
        
        switch command {
        case .moveForward:
            changedPlayer.ship = ship.move()
        case .moveBackward:
            changedPlayer.ship = ship.move(backwards: true)
        case .wait:
            break
        }
        
        changedPlayer.actionPoints -= 1
        
        return changedPlayer
    }
    
    func spendShipPoints(on stat: String, amount: Int) -> Player {
        guard amount <= shipPoints else {
            return self
        }
        
        guard ["ARMAMENT", "ARMOR", "THRUST"].contains(stat.uppercased()) else {
            return self
        }
        
        var updatedPlayer = self
        updatedPlayer.shipPoints -= amount
        updatedPlayer.ship = ship.customizeShip(stat, amount: amount)
        return updatedPlayer
    }
}
