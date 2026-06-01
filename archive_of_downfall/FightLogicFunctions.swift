//
//  FightLogicFunctions.swift
//  archive_of_downfall
//
//  Created by Student on 5/29/26.
//
import Foundation

func clash(player: Nugget, enemy: Nugget) {
    var playerRoll = roll(min: player.deck[0].dice[0].minRoll,max: player.deck[0].dice[0].maxRoll)
    var enemyRoll = roll(min: enemy.deck[0].dice[0].minRoll,max: enemy.deck[0].dice[0].maxRoll)
    if () {
        
    }
}

func roll(min: Int, max: Int) -> Int {
    return Int.random(in: min...max)
}
