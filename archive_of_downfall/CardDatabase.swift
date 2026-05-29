//
//  Cards.swift
//  archive_of_downfall
//
//  Created by Student on 5/29/26.
//
import Foundation

struct CardDatabase {
    //0-Cost Cards
    
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
    
    //Starter Deck
    static let starterDeck: [Card] = [
        lightAttack, lightAttack, lightAttack
    ]
}
