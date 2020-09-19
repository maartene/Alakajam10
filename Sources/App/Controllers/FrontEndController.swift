//
//  File.swift
//  
//
//  Created by Maarten Engels on 18/09/2020.
//

import Foundation
import Vapor

extension Application {
    var simulation: Simulation {
        get { self.storage[Simulation.self]! }
        set { self.storage[Simulation.self] = newValue }
    }
}

extension Simulation: StorageKey {
    public typealias Value = Simulation
}

struct CreateSimulation: LifecycleHandler {
    func willBoot(_ application: Application) throws {
        let simulation = Simulation()
        application.simulation = simulation
        application.logger.info("Created new simulation with players: \(simulation.players)")
    }
}


func createFrontEndRoutes(_ app: Application) {
    app.get("") { req -> String in
        "Hello, world!"
    }
    
    app.get("main") { req -> EventLoopFuture<View> in
        struct MainContext: Content {
            let player: Player
            let maxActionPoints: Int
            let apDelay: Int
            let stints: [StintInfo]
        }
        
        struct StintInfo: Codable {
            let stintID: Int
            let progress: Double
        }
 
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        // first check to see wether we can update
        if app.simulation.canUpdate(at: Date()) {
            var updatedSimulation = app.simulation
            while updatedSimulation.canUpdate(at: Date()) {
                updatedSimulation = updatedSimulation.update(at: Date())
                print(updatedSimulation)
            }
        
            app.simulation = updatedSimulation
        }
        
        let stints = (0 ..< 5).map { value -> StintInfo in
            if player.ship.position > Double(value) {
                let progress = (player.ship.position - Double(value)) * 100.0
                return StintInfo(stintID: value, progress: min(100.0, progress))
            } else {
                return StintInfo(stintID: value, progress: 0)
            }
        }
        
        print(stints)
        
        let mainContext = MainContext(player: player, maxActionPoints: PLAYER_MAX_ACTION_POINTS, apDelay: Int(SIMULATION_NEXT_UPDATE_DELAY_MINUTES), stints: stints)
        return req.view.render("main", mainContext)
    }
    
    // MARK: Customize your ship
    app.get("ship", "customize") { req -> EventLoopFuture<View> in
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        return req.view.render("customizeShip", ["player": player])
    }
    
    app.get("ship", "add", ":stat") { req -> Response in
        guard let statName = req.parameters.get("stat") else {
            throw Abort(.badRequest, reason: "No valid string found for parameter 'stat'")
        }
        
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        let updatedPlayer = player.spendShipPoints(on: statName, amount: 1)
        app.simulation.replace(updatedPlayer)
        
        return req.redirect(to: "/ship/customize")
    }
    
    app.get("ship", "remove", ":stat") { req -> Response in
        guard let statName = req.parameters.get("stat") else {
            throw Abort(.badRequest, reason: "No valid string found for parameter 'stat'")
        }
        
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        let updatedPlayer = player.spendShipPoints(on: statName, amount: -1)
        app.simulation.replace(updatedPlayer)
        
        return req.redirect(to: "/ship/customize")
    }
    
    
    // MARK: Player actions
    
    app.get("command", ":number") { req -> Response in
        guard let numberString = req.parameters.get("number") else {
            throw Abort(.badRequest, reason: "No valid string found for parameter 'number'")
        }
        
        guard let number = Int(numberString) else {
            throw Abort(.badRequest, reason: "\(numberString) is not a valid Integer")
        }
        
        guard let command = GameCommand(rawValue: number) else {
            throw Abort(.notFound, reason: "No command found for number \(number)")
        }
        
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        app.simulation = app.simulation.executeCommand(command, for: player)
        
        return req.redirect(to: "/main")
    }
    
    
}

func getPlayerFromSession(_ req: Request, in simulation: Simulation) -> Player? {
    simulation.players.first
}
