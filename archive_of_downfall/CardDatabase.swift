//
//  Cards.swift
//  archive_of_downfall
//
//  Created by Student on 5/29/26.
//
import Foundation

struct CardDatabase {
    //0-Cost Cards
    static let evade = Card (
        name: "Evade",
        cost: 0,
        dice: [Dice(minRoll: 1, maxRoll: 4, type: .evade)]
    )
    static let block = Card (name: "block", cost: 0, dice: [Dice(minRoll: 100, maxRoll: 101, type: .block)])
    //1-Cost Cards
    static let lightAttack = Card(
        name: "Light Attack",
        cost: 1,
        dice: [
            Dice(minRoll: 2, maxRoll: 3, type: .atk, atkType: .pierce),
            Dice(minRoll: 1, maxRoll: 4, type: .atk, atkType: .blunt)
        ]
    )
    //2-Cost Cards
    
    //3-Cost Cards
    static let focusedStrikes = Card(
        name: "Focused Strikes",
        cost: 3,
        dice: [
            Dice(minRoll: 3, maxRoll: 5, type: .atk, atkType: .slash),
            Dice(minRoll: 3, maxRoll: 5, type: .atk, atkType: .slash),
            Dice(minRoll: 1, maxRoll: 3, type: .atk, atkType: .pierce)


        ]
    )
    
    //Starter Deck
    static let starterDeck: [Card] = [
        lightAttack, lightAttack, lightAttack,
        lightAttack, lightAttack, lightAttack,
        lightAttack, lightAttack, lightAttack
    ]
}
