@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testHelloWorld() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }
    
    func testUpdateSimulation() throws {
        let simulation = Simulation()
        let updatedSimulation = simulation.update(at: simulation.nextUpdateTime)
        
        XCTAssertGreaterThan(updatedSimulation.ticks, simulation.ticks, "ticks")
        XCTAssertGreaterThan(updatedSimulation.nextUpdateTime, simulation.nextUpdateTime, "time")
        
    }
    
    func testMoveShip() throws {
        let MAX_STEPS = 10_000
        var ship = Ship(sector: 0)
        
        var count = 0
        while ship.position < 5.0 && count < MAX_STEPS {
            ship = ship.move()
            count += 1
        }
        
        if count > MAX_STEPS {
            XCTFail("Unable to reach destination in \(MAX_STEPS) steps.")
            return
        }
        
        print("Moved \(ship) to position in \(count) steps. Average speed: \(ship.speed)")
    }
    
    func testSimulationUpdateIncreasesPlayerActionPoints() throws {
        let simulation = Simulation()
        XCTAssertLessThan(simulation.players.first!.actionPoints, PLAYER_MAX_ACTION_POINTS)
        
        let updatedSimulation = simulation.update(at: Date())
        XCTAssertGreaterThan(updatedSimulation.players.first!.actionPoints, simulation.players.first!.actionPoints)
        
        
        
    }
    
    func testCombat() throws {
        var simulation = Simulation()
        var player1 = Player(name: "player1", sector: 0)
        player1.ship.armament = 1
        player1.ship.position = 1.3
        player1.ship.sector = 0
        var player2 = Player(name: "player2", sector: 0)
        player2.ship.armament = 1
        player2.ship.position = 1.4
        player2.ship.sector = 0
        
        simulation.players.append(player1)
        simulation.players.append(player2)
        
        let combatResult = simulation.resolveCombat(player1: player1, player2: player2).players
        print(combatResult)
        
        XCTAssertEqual(combatResult[1].ship.position == 0, combatResult[2].ship.position == 0)
    }
    
    func testCombatFromStint() throws {
        var simulation = Simulation()
        var player1 = Player(name: "player1", sector: 0)
        player1.ship.armament = 1
        player1.ship.position = 1.3
        player1.ship.sector = 0
        var player2 = Player(name: "player2", sector: 0)
        player2.ship.armament = 1
        player2.ship.position = 1.4
        player2.ship.sector = 0
        
        simulation.players.append(player1)
        simulation.players.append(player2)
        
        let combatResult = simulation.processCombat(for: player1)
        print(combatResult.players)
        
        XCTAssertEqual(combatResult.players[1].ship.position == 0, combatResult.players[2].ship.position == 0)
    }
}
