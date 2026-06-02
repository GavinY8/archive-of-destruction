//
//  FightLogicFunctions.swift
//  archive_of_downfall
//
//  Created by Student on 5/29/26.
//
import Foundation

func clash(player: inout Nugget, enemy: inout Nugget) {
    // 1. Both units choose a card from their hand
    guard var playerCard = chooseCard(unit: &player, strategy: "highest_cost"),
          var enemyCard = chooseCard(unit: &enemy, strategy: "highest_cost") else {
        print("Clash aborted: One or both units couldn't play a card.")
        return
    }
    
    // 2. Loop while BOTH cards still have combat dice left to clash with
    while !playerCard.dice.isEmpty && !enemyCard.dice.isEmpty {
        // Remove the first die from each card's queue
        let playerDie = playerCard.dice.removeFirst()
        let enemyDie = enemyCard.dice.removeFirst()
        
        // Roll the dice
        let playerRoll = roll(min: playerDie.minRoll, max: playerDie.maxRoll)
        let enemyRoll = roll(min: enemyDie.minRoll, max: enemyDie.maxRoll)
        
        print("🎲 \(player.name) rolled \(playerRoll) (\(playerDie.type)) vs \(enemy.name) rolled \(enemyRoll) (\(enemyDie.type))")
        // Add your Evade/Block logic checks down here...
    }
}


func roll(min: Int, max: Int) -> Int {
    return Int.random(in: min...max)
}

func attack() {
    
}

func chooseCard(unit: inout Nugget, strategy: String = "highest_cost") -> Card? {
    // 1. Filter hand for cards the unit can actually afford with their current light
    let affordableCards = unit.hand.filter { $0.cost <= unit.light }
    
    // 2. If no cards are affordable, return nil (Unit must pass or use a 0-cost card)
    guard !affordableCards.isEmpty else {
        return nil
    }
    
    // 3. Select a card based on strategy
    let selectedCard: Card
    switch strategy {
    case "highest_cost":
        // Library of Ruina AI often prioritizes spending high-cost pages first
        selectedCard = affordableCards.max(by: { $0.cost < $1.cost })!
    case "lowest_cost":
        selectedCard = affordableCards.min(by: { $0.cost < $1.cost })!
    case "random":
        selectedCard = affordableCards.randomElement()!
    default:
        selectedCard = affordableCards.first!
    }
    
    // 4. Pay the Light cost
    unit.light -= selectedCard.cost

    // 5. Remove the card from hand and move it to discard pile
    if let index = unit.hand.firstIndex(where: { $0.name == selectedCard.name }) {
        let removedCard = unit.hand.remove(at: index)
        unit.discard.append(removedCard)
    }
    
    return selectedCard
}
