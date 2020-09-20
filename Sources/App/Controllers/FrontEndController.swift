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
        let simulation = Simulation(botCount: 10)
        application.simulation = simulation
        application.logger.info("Created new simulation with players: \(simulation.players)")
    }
}


func createFrontEndRoutes(_ app: Application) {
    app.get("") { req -> EventLoopFuture<View> in
        req.view.render("index")
    }
    
    app.get("main") { req -> EventLoopFuture<View> in
        struct MainContext: Content {
            let player: Player
            let maxActionPoints: Int
            let apDelay: Int
            let stints: [StintInfo]
            let sectors: Int
            let messages: [MessageInfo]
        }
        
        struct StintInfo: Codable {
            let stintID: Int
            let progress: Double
        }
        
        struct MessageInfo: Codable {
            let id: Int
            let message: String
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
        
        let messages = player.messages.enumerated().map({ message in
            MessageInfo(id: message.offset, message: message.element)
        })
                
        let mainContext = MainContext(player: player, maxActionPoints: PLAYER_MAX_ACTION_POINTS, apDelay: Int(SIMULATION_NEXT_UPDATE_DELAY_MINUTES), stints: stints, sectors: app.simulation.sectorCountForStint(player.ship.stint), messages: messages)
        return req.view.render("main", mainContext)
    }
    
    // MARK: Create an account
    app.get("create", "player") { req -> EventLoopFuture<View> in
        req.view.render("createPlayer")
    }
    
    app.post("create", "player") { req -> EventLoopFuture<View> in
        struct CreateCharacterContext: Codable {
            var errorMessage = "noError"
            var uuid = "unknown"
        }
        let name: String = try req.content.get(at: "name")

        var context = CreateCharacterContext()
        
        let player = Player(name: name, sector: (0 ..< app.simulation.sectorCountForStint(0)).randomElement() ?? 0)
        app.simulation.players.append(player)
        context.uuid = String(player.id)
        
        return req.view.render("userCreated", context)
    }
    
    // MARK: Login
    app.post("login") { req -> Response in
        let idString: String = (try? req.content.get(at: "playerid")) ?? ""
        
        guard UUID(idString) != nil else {
            print("\(idString) is not a valid user id")
            return req.redirect(to: "/")
        }
        
        req.session.data["playerID"] = idString
        return req.redirect(to: "/main")
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
    
    app.get("dismiss", "message", ":number") { req -> Response in
        guard let numberString = req.parameters.get("number") else {
            throw Abort(.badRequest, reason: "No valid string found for parameter 'number'")
        }
        
        guard let number = Int(numberString) else {
            throw Abort(.badRequest, reason: "\(numberString) is not a valid Integer")
        }
        
        guard let player = getPlayerFromSession(req, in: app.simulation) else {
            throw Abort(.unauthorized, reason: "Not logged in.")
        }
        
        var changedPlayer = player
        changedPlayer.messages.remove(at: number)
        app.simulation.replace(changedPlayer)
        
        return req.redirect(to: "/main")
    }
    
    // MARK: DEBUG endpoints
    app.get("debug", "allPlayers") { req -> [Player] in
        app.simulation.players
    }
}

func getPlayerIDFromSession(on req: Request) -> UUID? {
    if req.hasSession, let playerID = req.session.data["playerID"] {
        return UUID(playerID)
    }
    return nil
}

func getPlayerFromSession(_ req: Request, in simulation: Simulation) -> Player? {
    //simulation.players.first
    
    guard let id = getPlayerIDFromSession(on: req) else {
        req.logger.error("No ID found in session.")
        return nil
    }
    
    guard let player = simulation.players.first(where: {player in player.id == id }) else {
        req.logger.error("No player with id \(id) found in simulation.")
        return nil
    }
    
    return player
}
