//
//  File.swift
//  
//
//  Created by Maarten Engels on 19/09/2020.
//

import Foundation
import Vapor

struct Ship: Content {
    enum ShipCodingKeys: CodingKey {
        case armament
        case armor
        case thrust
        case weight
        case speed
        case position
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ShipCodingKeys.self)
        try container.encode(armament, forKey: .armament)
        try container.encode(armor, forKey: .armor)
        try container.encode(thrust, forKey: .thrust)
        try container.encode(weight, forKey: .weight)
        try container.encode(speed, forKey: .speed)
        try container.encode(position, forKey: .position)
    }
    
    var armament = 0
    var armor = 0
    var thrust = 0
    
    var weight: Int {
        SHIP_BASE_WEIGHT +
            armament * SHIP_ARMAMENT_UNIT_WEIGHT +
            armor * SHIP_ARMOR_UNIT_WEIGHT
    }
    
    var speed: Double {
        Double(SHIP_BASE_SPEED + thrust * SHIP_THRUST_UNIT_SPEED) / Double(weight)
    }
    
    var position: Double = 0
    
    func move(backwards: Bool = false) -> Ship {
        var movedShip = self
        
        if backwards == false {
            movedShip.position += speed / DISTANCE_BETWEEN_BASES
            movedShip.position = min(Double(NUMBER_OF_STINTS), movedShip.position)
        } else {
            movedShip.position -= speed / DISTANCE_BETWEEN_BASES
            movedShip.position = max(0, movedShip.position)
        }
        
        return movedShip
    }
    
    func customizeShip(_ stat: String, amount: Int) -> Ship {
        var customizedShip = self
        
        switch stat.uppercased() {
        case "ARMAMENT":
            customizedShip.armament += amount
        case "ARMOR":
            customizedShip.armor += amount
        case "THRUST":
            customizedShip.thrust += amount
        default:
            // do nothing
            break
        }
        
        return customizedShip
    }
}
