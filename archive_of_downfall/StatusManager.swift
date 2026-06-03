//
//  StatusFunctions.swift
//  archive_of_downfall
//
//  Created by Student on 6/1/26.
//

import Foundation

struct StatusManager {
    static func getStacks(of type: StatusType, on nugget: Nugget) -> Int {
        return nugget.statuses.first(where: {$0.type == type})?.stacks ?? 0
    }
    
    static func addStatus(type: StatusType, amount: Int, to nugget: inout Nugget) {
        if let index = nugget.statuses.firstIndex(where: { $0.type == type }) {
            nugget.statuses[index].stacks += amount
        } else {
            let newStatus = Status(type: type, stacks: amount)
            nugget.statuses.append(newStatus)
        }
    }
    
    static func setStatus(type: StatusType, amount: Int, to nugget: inout Nugget) {
        if let index = nugget.statuses.firstIndex(where: { $0.type == type }) {
            nugget.statuses[index].stacks = amount
        } else {
            let newStatus = Status(type: type, stacks: amount)
            nugget.statuses.append(newStatus)
        }
    }
    
    static func removeStatus(type: StatusType, from nugget: inout Nugget) {
        nugget.statuses.removeAll(where: {$0.type == type})
    }
    
    static func triggerAttackStartStatuses(on nugget: inout Nugget) {
        // 2. Process Page-Modifying Statuses (Strength, Feeble, Endurance, Disarm, Paralysis)
        // Must be calculated after player assigns cards to dice, right before clash resolution.
        let strength = getStacks(of: .strength, on: nugget)
        let feeble = getStacks(of: .feeble, on: nugget)
        let endurance = getStacks(of: .endurance, on: nugget)
        let disarm = getStacks(of: .disarm, on: nugget)
        let paralysis = getStacks(of: .paralysis, on: nugget)
        
        for i in 0..<nugget.speedDice.count {
            guard var assignedCard = nugget.speedDice[i].assignedCard else { continue }
            
            // Track how many dice we need to paralyze for this specific card
            var paralysisRemaining = paralysis
            var diceIndices = Array(0..<assignedCard.dice.count)
            diceIndices.shuffle() // Ruina paralyzes random dice on the page
            
            for j in 0..<assignedCard.dice.count {
                var die = assignedCard.dice[j]
                
                // Apply Strength / Feeble to Attack Dice
                if die.type == .atk {
                    die.minRoll = max(1, die.minRoll + strength - feeble)
                    die.maxRoll = max(1, die.maxRoll + strength - feeble)
                }
                // Apply Endurance / Disarm to Defensive Dice
                else {
                    die.minRoll = max(1, die.minRoll + endurance - disarm)
                    die.maxRoll = max(1, die.maxRoll + endurance - disarm)
                }
                
                // Apply Paralysis (Reduces Max Roll of random dice by 3)
                if paralysisRemaining > 0 && diceIndices.contains(j) {
                    die.maxRoll = max(1, die.maxRoll - 3)
                    if die.maxRoll < die.minRoll {
                        die.minRoll = die.maxRoll
                    }
                    paralysisRemaining -= 1
                }
                
                assignedCard.dice[j] = die
            }
            nugget.speedDice[i].assignedCard = assignedCard
        }
    }
    
    /// Triggered every single time this nugget rolls an offensive Combat Die
    static func triggerBleedStatus(on nugget: inout Nugget) {
        if let bleedIndex = nugget.statuses.firstIndex(where: { $0.type == .bleed }) {
            let stacks = nugget.statuses[bleedIndex].stacks
            
            // 1. Deal mid-combat damage equal to current stacks
            nugget.hp -= stacks
            
            // 2. Calculate decay (1/3 rounded up) using integer math ceiling formula: (X + 2) / 3
            let decaySubtraction = (stacks + 2) / 3
            let remaining = stacks - decaySubtraction
            
            // 3. Immediately update or remove the status so the NEXT die in the queue sees the new values
            if remaining > 0 {
                nugget.statuses[bleedIndex].stacks = remaining
            } else {
                nugget.statuses.remove(at: bleedIndex)
            }
        }
    }
    
    /// Triggered exclusively at Scene End (Ticks damage statuses down)
    static func triggerSceneEndStatuses(on nugget: inout Nugget) {
        // Process Burn Tick
        if let burnIndex = nugget.statuses.firstIndex(where: { $0.type == .burn }) {
            let stacks = nugget.statuses[burnIndex].stacks
            nugget.hp -= stacks
            
            let decaySubtraction = max(1, stacks / 3)
            let remaining = stacks - decaySubtraction
            
            if remaining > 0 {
                nugget.statuses[burnIndex].stacks = remaining
            } else {
                nugget.statuses.remove(at: burnIndex)
            }
        }
        
        // Clean up temporary next-turn statuses at the end of the combat round
        let expirationList: [StatusType] = [.strength, .feeble, .endurance, .disarm, .paralysis, .haste, .bind]
                nugget.statuses.removeAll(where: { expirationList.contains($0.type) })
    }
    
    
}
