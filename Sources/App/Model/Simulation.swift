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
        updatedSimulation.ticks += 1
        updatedSimulation.nextUpdateTime += SIMULATION_NEXT_UPDATE_DELAY_MINUTES * 60.0
        return updatedSimulation
    }
}
