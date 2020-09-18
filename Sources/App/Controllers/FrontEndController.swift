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
    app.get("hello") { req -> String in
        "Hello, world!"
    }
    
    app.get() { req -> String in
        let updatedSimulation = app.simulation.update(at: Date())
        print(updatedSimulation)
        app.simulation = updatedSimulation
        return "Update done!"
    }
}
