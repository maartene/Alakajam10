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
    
    init(botCount: Int = 0) {
        players = [Player]()
        players.append(Player(name: "testPlayer", sector: sectorCountForStint(0)))
        
        for i in 0 ..< botCount {
            var bot = Player(name: "Bot \(i)")
            //bot.ship.armament = 0
            bot.ship.position = Double.random(in: (0.5 ..< 4.5))
            bot.ship.armor = bot.ship.stint > 2 ? 1 : 0
            bot.ship.armament = bot.ship.stint > 3 ? 1 : 0
            bot.ship.armament = bot.ship.stint > 4 ? 2 : 0
            players.append(bot)
        }
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
        let changedPlayer = player.executeCommand(command, in: self)
        
        var changedSimulation = self
        changedSimulation.replace(changedPlayer)
        changedSimulation = changedSimulation.processCombat(for: changedPlayer)
        
        return changedSimulation
    }
    
    mutating func replace(_ player: Player) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        }
    }
    
    func sectorCountForStint(_ stint: Int) -> Int {
        //let sectorCount =  max(0, Int(log2(Double(players.count + 1))) + 1 - NUMBER_OF_STINTS)
        //return Int(pow(2.0, Double(sectorCount + NUMBER_OF_STINTS - stint)))
        
        var sectorCount = Int(pow(2.0, Double(NUMBER_OF_STINTS)))
        var power = NUMBER_OF_STINTS
        while sectorCount < players.count {
            sectorCount *= 2
            power += 1
        }
        
        var result = sectorCount
        for _ in NUMBER_OF_STINTS ..< stint + power {
            result /= 2
        }
        return result
    }
    
    func processCombat(for player: Player) -> Simulation {
        var updatedSimulation = self
        if player.ship.stint > 0 && player.ship.stint < NUMBER_OF_STINTS {
            let otherPlayersInStint = players.filter { otherPlayer in
                otherPlayer.id != player.id && otherPlayer.ship.stint == player.ship.stint
            }
            
            // this should filter based on range
            let otherPlayersInRange = otherPlayersInStint
            
            // find the closest one
            let sortedOtherPlayers = otherPlayersInRange.sorted { player1, player2 in
                abs(player1.ship.position - player.ship.position) < abs(player2.ship.position - player.ship.position)
            }
            
            if let closestAdversary = sortedOtherPlayers.first {
                updatedSimulation = resolveCombat(player1: player, player2: closestAdversary)
            }
        }
        return updatedSimulation
    }
    
    func resolveCombat(player1: Player, player2: Player) -> Simulation {
        //print("Resolving combat between \(player1) and \(player2)")
        var changedPlayer1 = player1
        var changedPlayer2 = player2
        
        let sectorCountForCurrentStint = sectorCountForStint(changedPlayer1.ship.stint)
        let sectorCountForStint0 = sectorCountForStint(0)
        
        if player1.ship.armament > player2.ship.armor {
            changedPlayer2.ship.armor -= 1
            
            // bump to different sector
            changedPlayer2.ship.sector = (sectorCountForCurrentStint + 1) % sectorCountForCurrentStint
            changedPlayer2.logMessage("You took damage from \(changedPlayer1.name)'s ship.", severity: "warning")
            changedPlayer1.logMessage("You damaged \(changedPlayer2.name)'s ship.")
        }
        
        if player2.ship.armament > player1.ship.armor {
            changedPlayer1.ship.armor -= 1
            
            // bump to different sector
            changedPlayer1.ship.sector = (sectorCountForCurrentStint + 1) % sectorCountForCurrentStint
            changedPlayer1.logMessage("You took damage from \(changedPlayer2.name)'s ship.", severity: "warning")
            changedPlayer2.logMessage("You damaged \(changedPlayer1.name)'s ship.")
        }
        
        if changedPlayer1.ship.armor < 0 {
            // player died
            changedPlayer1.ship = Ship(sector: (0..<sectorCountForStint0).randomElement() ?? 0)
            changedPlayer1.shipPoints = 3
            changedPlayer1.logMessage("Your ship was destroyed, you can try again.", severity: "danger")
            changedPlayer2.logMessage("You destroyed \(changedPlayer1.name)'s ship.")
        }
        
        if changedPlayer2.ship.armor < 0 {
            // player died
            changedPlayer2.ship = Ship(sector: (0..<sectorCountForStint0).randomElement() ?? 0)
            changedPlayer2.shipPoints = 3
            changedPlayer2.logMessage("Your ship was destroyed, you can try again.", severity: "danger")
            changedPlayer1.logMessage("You destroyed \(changedPlayer2.name)'s ship.")
        }
        
        var changedSimulation = self
        changedSimulation.replace(changedPlayer1)
        changedSimulation.replace(changedPlayer2)
        return changedSimulation
    }
}

enum GameCommand: Int {
    case wait = 0
    case moveForward = 1
    case moveBackward = 2
    case scan = 3
}
