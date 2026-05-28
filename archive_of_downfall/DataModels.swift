//
//  Player.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//
import Foundation

struct Player {
    var numSpeedDice: Int
    var hp: Int
    var stagger: Int
    var light: Int
    var maxLight: Int
    var dice: [Dice]
    
    var slash: Double
    var pierce: Double
    var blunt: Double
    
    var staggerSlash: Double
    var staggerPierce: Double
    var staggerBlunt: Double
}

struct Dice {
    var min: Int
    var max: Int
    var atk: Card
}

struct Card {
    var numDice: Int
    var cost: Int
        
}
