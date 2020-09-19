//
//  File.swift
//  
//
//  Created by Maarten Engels on 18/09/2020.
//

import Foundation
import Vapor

struct Simulation: Content {
    var players: [Player]
    var nextUpdateTime = Date()
    var ticks = 0
    
    init() {
        players = [Player(name: "testPlayer")]
    }
    
    func canUpdate(at date: Date) -> Bool {
        date >= nextUpdateTime
    }
    
    func update(at date: Date) -> Simulation {
        guard canUpdate(at: date) else {
            return self
        }
        
        var updatedSimulation = self
        
        updatedSimulation.players = players.map { player in player.update() }
        updatedSimulation.ticks += 1
        updatedSimulation.nextUpdateTime += SIMULATION_NEXT_UPDATE_DELAY_MINUTES * 60.0
        
        return updatedSimulation
    }
    
    func executeCommand(_ command: GameCommand, for player: Player) -> Simulation {
        let changedPlayer = player.executeCommand(command)
        
        var changedSimulation = self
        changedSimulation.replace(changedPlayer)
        return changedSimulation
    }
    
    mutating func replace(_ player: Player) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        }
    }
    
}

enum GameCommand: Int {
    case wait = 0
    case moveForward = 1
    case moveBackward = 2
}
