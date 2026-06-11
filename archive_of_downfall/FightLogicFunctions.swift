//
//  FightLogicFunctions.swift
//  archive_of_downfall
//
//  Created by Student on 5/29/26.
//
import Foundation

func turnStart(player: inout Nugget, enemy: inout Nugget) {
    if !player.isStaggered {
        if (player.light < player.maxLight) {
            player.light+=1
        }
    }

    if !enemy.isStaggered {
        if (enemy.light < enemy.maxLight) {
            enemy.light+=1
        }
    }
}

func turnEnd(player: inout Nugget, enemy: inout Nugget) {
    StatusManager.triggerSceneEndStatuses(on: &player)
    StatusManager.triggerSceneEndStatuses(on: &enemy)
}

func tryClash(player: inout Nugget, target: inout Nugget, playerSpeed: Int, enemySpeed: Int,playerCard: Card, enemyCard: Card) {
    if playerSpeed > enemySpeed {
        let newClash = ClashAction(
            player: player.name,
            target: target.name,
            playerCard: playerCard,
            enemyCard: enemyCard
        )
    }
}

///we need another function to check for if a clash even occurs, but i think this clash is done
func clash(player: inout Nugget, enemy: inout Nugget, playerCard: Card, enemyCard: Card, events: inout [CombatEvent]) {
    var tempP = player
    tempP.page.speedDice = [SpeedDice(min: 1, max: 1, assignedCard: playerCard)]
    StatusManager.triggerAttackStartStatuses(on: &tempP)
    var tempPCard = tempP.page.speedDice[0].assignedCard!
    var tempE = enemy
    tempE.page.speedDice = [SpeedDice(min: 1, max: 1, assignedCard: enemyCard)]  
    StatusManager.triggerAttackStartStatuses(on: &tempE)                          
    var tempECard = tempE.page.speedDice[0].assignedCard!

    
    while (!tempPCard.dice.isEmpty && !tempECard.dice.isEmpty && !player.isStaggered && !enemy.isStaggered) {
        StatusManager.triggerBleedStatus(on: &player)
        StatusManager.triggerBleedStatus(on: &enemy)
        
        let tempPDice = tempPCard.dice.first!
        let tempEDice = tempECard.dice.first!

        
        var pRoll = roll(min: tempPDice.minRoll, max: tempPDice.maxRoll)
        var eRoll = roll(min: tempEDice.minRoll, max: tempEDice.maxRoll)
        
        //check dice type here haha funny 300000000 line code
        events.append(
                CombatEvent(
                    type: .roll,
                    actorName: player.name,
                    cardName: playerCard.name,
                    dieIndex: 0,    // or track which die this is
                    roll: pRoll,
                    hpDamage: nil,
                    staggerDamage: nil
                )
            )
        
        ///player attack
        if (tempPDice.type == .atk && tempEDice.type == .atk) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                attack(attacker: &player, defender: &enemy, chosenDice: tempPDice, diceRoll: pRoll)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                attack(attacker: &enemy, defender: &player, chosenDice: tempEDice, diceRoll: eRoll)
            } else {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
            }
        } else if (tempPDice.type == .atk && tempEDice.type == .block) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                pRoll -= eRoll
                attack(attacker: &player, defender: &enemy, chosenDice: tempPDice, diceRoll: pRoll)
            } else if (pRoll <= eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                player.stagger -= (eRoll-pRoll)
                staggerCheck(target: &player)
            }
        } else if (tempPDice.type == .atk && tempEDice.type == .evade) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                attack(attacker: &player, defender: &enemy, chosenDice: tempPDice, diceRoll: pRoll)
            } else if (pRoll <= eRoll) {
                tempPCard.dice.removeFirst()
                enemy.stagger = min(enemy.page.maxStagger, enemy.stagger+eRoll)
            }
        }
        
        ///player block
        else if (tempPDice.type == .block && tempEDice.type == .atk) {
            if (pRoll >= eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                enemy.stagger-=(pRoll-eRoll)
                staggerCheck(target: &enemy)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                eRoll-=pRoll
                attack(attacker: &enemy, defender: &player, chosenDice: tempEDice, diceRoll: eRoll)
            }
        } else if (tempPDice.type == .block && tempEDice.type == .block) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                enemy.stagger-=pRoll
                staggerCheck(target: &enemy)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                player.stagger-=eRoll
                staggerCheck(target: &player)
            } else {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
            }
        } else if (tempPDice.type == .block && tempEDice.type == .evade) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                enemy.stagger-=pRoll
                staggerCheck(target: &enemy)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                enemy.stagger = min(enemy.page.maxStagger, enemy.stagger + eRoll)
            } else {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
            }
        }
        
        
        ///player evade
        else if (tempPDice.type == .evade && tempEDice.type == .atk) {
            if (pRoll >= eRoll) {
                tempECard.dice.removeFirst()
                player.stagger = min(player.page.maxStagger, player.stagger+pRoll)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                attack(attacker: &enemy, defender: &player, chosenDice: tempEDice, diceRoll: eRoll)
            }
        } else if (tempPDice.type == .evade && tempEDice.type == .block) {
            if (pRoll > eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                player.stagger=max(player.page.maxStagger, player.stagger+pRoll)
            } else if (pRoll < eRoll) {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
                player.stagger-=eRoll
                staggerCheck(target: &player)
            } else {
                tempECard.dice.removeFirst()
                tempPCard.dice.removeFirst()
            }
        } else if (tempPDice.type == .evade && tempEDice.type == .evade) {
            tempECard.dice.removeFirst()
            tempPCard.dice.removeFirst()
        }
    }
    
    
    //checks for remaining dice after the clash removes them
    while (!tempPCard.dice.isEmpty) {
        StatusManager.triggerBleedStatus(on: &player)
        
        let tempPDice = tempPCard.dice.first!
        
        let pRoll = roll(min: tempPDice.minRoll, max: tempPDice.maxRoll)
        
        attack(attacker: &player, defender: &enemy, chosenDice: tempPDice, diceRoll: pRoll)
        tempPCard.dice.removeFirst()
    }
    
    while (!tempECard.dice.isEmpty) {
        StatusManager.triggerBleedStatus(on: &enemy)
        
        let tempEDice = tempECard.dice.first!
        
        let eRoll = roll(min: tempEDice.minRoll, max: tempEDice.maxRoll)
        
        attack(attacker: &enemy, defender: &player, chosenDice: tempEDice, diceRoll: eRoll)
        tempECard.dice.removeFirst()
    }

}

//func clash(player: inout Nugget, enemy: inout Nugget) {
//    // 1. Both units choose a card from their hand
//    guard var playerCard = chooseCard(unit: &player, strategy: "highest_cost"),
//          var enemyCard = chooseCard(unit: &enemy, strategy: "highest_cost") else {
//        print("Clash aborted: One or both units couldn't play a card.")
//        return
//    }
//    
//    // 2. Loop while BOTH cards still have combat dice left to clash with
//    while !playerCard.dice.isEmpty && !enemyCard.dice.isEmpty {
//        // Remove the first die from each card's queue
//        let playerDie = playerCard.dice.removeFirst()
//        let enemyDie = enemyCard.dice.removeFirst()
//        
//        // Roll the dice
//        let playerRoll = roll(min: playerDie.minRoll, max: playerDie.maxRoll)
//        let enemyRoll = roll(min: enemyDie.minRoll, max: enemyDie.maxRoll)
//        
//        print("🎲 \(player.name) rolled \(playerRoll) (\(playerDie.type)) vs \(enemy.name) rolled \(enemyRoll) (\(enemyDie.type))")
//        // Add your Evade/Block logic checks down here...
//    }
//    
//    
//}


func roll(min: Int, max: Int) -> Int {
    return Int.random(in: min...max)
}


func attack(attacker: inout Nugget, defender: inout Nugget, chosenDice: Dice, diceRoll: Int) {
    let (hpDmg, staggerDmg) = calculateDamage(baseRoll: diceRoll, type: chosenDice.atkType, target: defender)
    
    defender.hp = max(0, defender.hp - hpDmg)
    defender.stagger = max(0, defender.stagger - staggerDmg)
    
    staggerCheck(target: &defender)
}

///ignore this, don't use this for attack after clash because it assumes all dice of a card are there
func unopposedAttack(attacker: inout Nugget, defender: inout Nugget, chosenCard: Card) {
    // 1. Create a deep local copy of the card so mutations do not ruin your deck/hand blueprints
    let temporaryCardCopy = chosenCard
    
    // 2. Wrap it inside a temporary speed die so your original status structure can parse it safely
    let temporarySpeedDie = SpeedDice(min: 1, max: 1, assignedCard: temporaryCardCopy)
    
    // 3. Create a mock nugget container to isolate modifications safely
    var mockAttacker = attacker
    mockAttacker.page.speedDice = [temporarySpeedDie]
    
    // 4. Run your exact status preparation method safely on the mock target
    StatusManager.triggerAttackStartStatuses(on: &mockAttacker)
    
    // 5. Extract the modified card out of the processed isolated speed slot
    var processedCard = mockAttacker.page.speedDice[0].assignedCard!
    
    // 6. Run your dice queue processing loop
    while !processedCard.dice.isEmpty {
        let modifiedDie = processedCard.dice.removeFirst()
        
        if modifiedDie.type == .atk {
            StatusManager.triggerBleedStatus(on: &attacker) // Bleed still ticks on real attacker hp
        }
        
        // Because stats were already backed into minRoll/maxRoll by your function,
        // we can now safely use a standard randomized roll without dynamic math helpers!
        let rollResult = roll(min: modifiedDie.minRoll, max: modifiedDie.maxRoll)
        print("🎲 \(attacker.name) rolls a pre-calculated \(rollResult) (Physical Type: \(String(describing: modifiedDie.atkType)))")
        
        // --- DAMAGE RESOLUTION LOGIC ---
        if modifiedDie.type == .atk {
            // 1. Calculate health and stagger damage using your flat-modifier logic
            let damage = calculateDamage(baseRoll: rollResult, type: modifiedDie.atkType, target: defender)
            
            // 2. Apply damage to the real defender nugget pools
            defender.hp = max(0, defender.hp - damage.healthDamage)
            defender.stagger = max(0, defender.stagger - damage.staggerDamage)
            
            print("💥 Deal to \(defender.name): \(damage.healthDamage) HP Damage | \(damage.staggerDamage) Stagger Damage")
            print("📊 \(defender.name) Status: HP (\(defender.hp)) | Stagger (\(defender.stagger))")
            
            // 3. Handle break state triggers if necessary
            if defender.hp <= 0 {
                print("💀 \(defender.name) has been defeated!")
                break
            }
            if defender.stagger <= 0 {
                print("🥴 \(defender.name) has been Staggered!")
                // Trigger any specific staggered state flags here if needed
            }
        }
    }
}


private func calculateDamage(baseRoll: Int, type: AtkType?, target: Nugget) -> (healthDamage: Int, staggerDamage: Int) {
    guard let type = type else { return (baseRoll, baseRoll) }
    
    // 1. Fetch status stacks
    let fragile = StatusManager.getStacks(of: .fragile, on: target)
    let protection = StatusManager.getStacks(of: .protection, on: target)
    let staggerProtection = StatusManager.getStacks(of: .staggerProtection, on: target)
    
    // 2. Apply flat status modifiers to the base roll first
    let healthStatusModifier = fragile - protection
    let modifiedHealthBase = max(0.0, Double(baseRoll + healthStatusModifier))
    
    // Stagger protection reduces incoming stagger damage
    let modifiedStaggerBase = max(0.0, Double(baseRoll - staggerProtection))
    
    // 3. Extract defensive weakness multipliers
    let healthMultiplier: Double
    let staggerMultiplier: Double
    
    switch type {
    case .slash:
        healthMultiplier = target.page.slash
        staggerMultiplier = target.page.staggerSlash
    case .pierce:
        healthMultiplier = target.page.pierce
        staggerMultiplier = target.page.staggerPierce
    case .blunt:
        healthMultiplier = target.page.blunt
        staggerMultiplier = target.page.staggerBlunt
    }
    
    // 4. Multiply modified base damage by weaknesses and round
    let healthDamage = max(0, Int((modifiedHealthBase * healthMultiplier).rounded()))
    let staggerDamage = max(0, Int((modifiedStaggerBase * staggerMultiplier).rounded()))
    
    return (healthDamage, staggerDamage)
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

private func handleStaggerRecovery(target: inout Nugget) {
    if target.isStaggered {
        target.isStaggered = false
        target.stagger = target.page.maxStagger // Fully restore the stagger pool
        print("🛡️ \(target.name) has recovered from Stagger!")
    }
}

func rollAllSpeedDice(for nugget: Nugget) -> [Int] {
    var rolledResults: [Int] = []
    
    let haste = StatusManager.getStacks(of: .haste, on: nugget)
    let bind = StatusManager.getStacks(of: .bind, on: nugget)
    
    for baseDie in nugget.page.speedDice {
        let finalMin = max(1, baseDie.min + haste - bind)
        let finalMax = max(1, baseDie.max + haste - bind)
        
        let rolledValue = roll(min: finalMin, max: finalMax)
        rolledResults.append(rolledValue)
    }
    
    return rolledResults
}

private func staggerCheck(target: inout Nugget) {
    if (target.stagger <= 0) {
        target.isStaggered = true
        target.stagger = 0
    }
}

func drawCards(nugget: inout Nugget, count: Int) {
    var deck = Deck()
    for _ in 0..<count {
        if let card = deck.drawCard(from: &nugget.deck, discard: &nugget.discard) {
            nugget.hand.append(card)
        }
    }
}
