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
    var messages = [String]()
    
    private(set) var actionPoints = 10
    
    init(name: String, sector: Int = 0) {
        self.id = UUID()
        self.name = name
        self.ship = Ship(sector: sector)
        // self.messages.append("Welcome \(name)!")
    }
    
    func update() -> Player {
        var updatedPlayer = self
        
        updatedPlayer.actionPoints += 1
        updatedPlayer.actionPoints = min(PLAYER_MAX_ACTION_POINTS, updatedPlayer.actionPoints)
        
        return updatedPlayer
    }
    
    func executeCommand(_ command: GameCommand, in simulation: Simulation) -> Player {
        var changedPlayer = self
        
        guard changedPlayer.actionPoints > 0 else {
            return self
        }
        
        switch command {
        case .moveForward:
            changedPlayer.ship = ship.move()
        case .moveBackward:
            changedPlayer.ship = ship.move(backwards: true)
        case .scan:
            changedPlayer.messages.append(contentsOf: Scan(in: simulation))
        case .wait:
            break
        }
        
        if Int(changedPlayer.ship.position) - Int(ship.position) >= 1 {
            // we went to a new stint!
            print("New stint!")
            changedPlayer.shipPoints += 1
            changedPlayer.ship.sector = (0 ..< simulation.sectorCountForStint(changedPlayer.ship.stint)).randomElement() ?? 0
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
    
    func Scan(in simulation: Simulation) -> [String] {
        let scannedPlayers = simulation.players.filter { player in
            player.id != id && abs(player.ship.position - ship.position) <= PLAYER_SCAN_DISTANCE
        }
        
        let sortedByDistance = scannedPlayers.sorted { p1, p2 in
            abs(p1.ship.position - ship.position) < abs(p2.ship.position - ship.position)
        }
        
        let scanResults = sortedByDistance.map { player in
            "SCAN RESULT: found ship: \(player.name) with \(player.ship.armament),\(player.ship.armor),\(player.ship.thrust) in sector: \(player.ship.stint) distance: \(abs(player.ship.position - ship.position))"
        }
        
        if scanResults.count > 0 {
            return scanResults
        } else {
            return ["\(simulation.ticks): Scan returned no results"]
        }
    }
}
