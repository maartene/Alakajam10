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
}
