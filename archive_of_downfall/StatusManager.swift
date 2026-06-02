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
    
    static func statusTrigger(of type: StatusType, on nugget: inout Nugget) {
        guard let index = nugget.statuses.firstIndex(where: { $0.type == type }) else { return }
        let currentStatus = nugget.statuses[index]
        
        switch type {
        case .burn:
            nugget.hp -= currentStatus.stacks
            let remainingStacks = (currentStatus.stacks * 2) / 3
                
            if remainingStacks > 0 {
                nugget.statuses[index].stacks = remainingStacks
            } else {
                nugget.statuses.remove(at: index)
            }
            
        case .paralysis:
            let stacksToApply = currentStatus.stacks
            guard stacksToApply > 0 else { break }
            
            for i in 0..<nugget.speedDice.count {
                guard let assignedCard = nugget.speedDice[i].assignedCard else { continue }
                var cardDiceIndices = Array(0..<assignedCard.dice.count)
                cardDiceIndices.shuffle()
                
                let targetDiceForCard = cardDiceIndices.prefix(stacksToApply)
                
                for j in targetDiceForCard {
                    let calculatedMax = (nugget.speedDice[i].assignedCard?.dice[j].maxRoll ?? 0) - 3
                    nugget.speedDice[i].assignedCard?.dice[j].maxRoll = max(1, calculatedMax)
                    
                    if let currentDie = nugget.speedDice[i].assignedCard?.dice[j] {
                        if currentDie.maxRoll < currentDie.minRoll {
                            nugget.speedDice[i].assignedCard?.dice[j].minRoll = currentDie.maxRoll
                        }
                    }
                }
            }
        
        case .strength:
            let bonusToApply = currentStatus.stacks
            guard bonusToApply > 0 else { break }
               
            for i in 0..<nugget.speedDice.count {
                guard let assignedCard = nugget.speedDice[i].assignedCard else { continue }
                for j in 0..<assignedCard.dice.count {
                    if assignedCard.dice[j].type == .atk {
                        nugget.speedDice[i].assignedCard?.dice[j].minRoll += bonusToApply
                        nugget.speedDice[i].assignedCard?.dice[j].maxRoll += bonusToApply
                    }
                }
            }
            
        case .feeble:
            let penalty = currentStatus.stacks
            guard penalty > 0 else { break }
               
            for i in 0..<nugget.speedDice.count {
                guard let assignedCard = nugget.speedDice[i].assignedCard else { continue }
                for j in 0..<assignedCard.dice.count {
                    if assignedCard.dice[j].type == .atk {
                        let calculatedMin = assignedCard.dice[j].minRoll - penalty
                        let calculatedMax = assignedCard.dice[j].maxRoll - penalty
                        
                        nugget.speedDice[i].assignedCard?.dice[j].minRoll = max(1, calculatedMin)
                        nugget.speedDice[i].assignedCard?.dice[j].maxRoll = max(1, calculatedMax)
                    }
                }
            }
            
        case .endurance:
            let bonusToApply = currentStatus.stacks
            guard bonusToApply > 0 else { break }
               
            for i in 0..<nugget.speedDice.count {
                guard let assignedCard = nugget.speedDice[i].assignedCard else { continue }
                for j in 0..<assignedCard.dice.count {
                    if assignedCard.dice[j].type != .atk {
                        nugget.speedDice[i].assignedCard?.dice[j].minRoll += bonusToApply
                        nugget.speedDice[i].assignedCard?.dice[j].maxRoll += bonusToApply
                    }
                }
            }
            
        case .disarm:
            let penalty = currentStatus.stacks
            guard penalty > 0 else { break }
               
            for i in 0..<nugget.speedDice.count {
                guard let assignedCard = nugget.speedDice[i].assignedCard else { continue }
                for j in 0..<assignedCard.dice.count {
                    if assignedCard.dice[j].type != .atk {
                        let calculatedMin = assignedCard.dice[j].minRoll - penalty
                        let calculatedMax = assignedCard.dice[j].maxRoll - penalty
                        
                        nugget.speedDice[i].assignedCard?.dice[j].minRoll = max(1, calculatedMin)
                        nugget.speedDice[i].assignedCard?.dice[j].maxRoll = max(1, calculatedMax)
                    }
                }
            }
            
        case .haste:
            let bonusToApply = currentStatus.stacks
            guard bonusToApply > 0 else { break }
            
            for i in 0..<nugget.speedDice.count {
                nugget.speedDice[i].min += bonusToApply
                nugget.speedDice[i].max += bonusToApply
            }
            
        case .bind:
            let penalty = currentStatus.stacks
            guard penalty > 0 else { break }
            
            for i in 0..<nugget.speedDice.count {
                let calculatedMin = nugget.speedDice[i].min - penalty
                let calculatedMax = nugget.speedDice[i].max - penalty
                
                nugget.speedDice[i].min = max(1, calculatedMin)
                nugget.speedDice[i].max = max(1, calculatedMax)
            }
            
        default:
            break
        }
    }
}
