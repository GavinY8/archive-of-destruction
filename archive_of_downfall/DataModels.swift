//
//  Player.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//
import Foundation

struct Nugget {
    var name: String
    
    var page: Page
    
    var hp: Int
    var stagger: Int
    
    var light: Int
    var maxLight: Int
    
    var deck: [Card]
    var hand: [Card]
    var discard: [Card]
    
    
    var statuses: [Status]
    
    var isStaggered: Bool = false
    var staggerJustApplied: Bool = false   // ← add this
}

struct Page {
    var maxhp: Int
    var maxStagger: Int
    var speedDice: [SpeedDice]
    
    var slash: Double
    var pierce: Double
    var blunt: Double
    
    var staggerSlash: Double
    var staggerPierce: Double
    var staggerBlunt: Double

    // Custom initializer with implicit parameters (_)
    init(
        _ maxhp: Int,
        _ maxStagger: Int,
        _ speedDice: [SpeedDice],
        _ slash: Double,
        _ pierce: Double,
        _ blunt: Double,
        _ staggerSlash: Double,
        _ staggerPierce: Double,
        _ staggerBlunt: Double
    ) {
        self.maxhp = maxhp
        self.maxStagger = maxStagger
        self.speedDice = speedDice
        self.slash = slash
        self.pierce = pierce
        self.blunt = blunt
        self.staggerSlash = staggerSlash
        self.staggerPierce = staggerPierce
        self.staggerBlunt = staggerBlunt
    }
}


struct SpeedDice {
    var min: Int
    var max: Int
    var assignedCard: Card?
}

struct Card {
    var id: UUID = UUID()
    var name: String
    var cost: Int
    var dice: [Dice]
}
struct Dice {
    var minRoll: Int
    var maxRoll: Int
    var type: DiceType
    var atkType: AtkType? = nil
    var onHit: [DiceEffect] = []   // ← add this
}

enum DiceEffect {
    case inflict(StatusType, stacks: Int)
    case heal(Int)
    case draw(Int)
    case gainLight(Int)
}

enum AtkType {
    case slash, blunt, pierce
}

enum DiceType {
    case atk, evade, block
}

enum StatusType {
    case bleed, paralysis, burn, protection, staggerProtection, fragile, strength, feeble, endurance, disarm, haste, bind
}

struct Status {
    var type: StatusType
    var stacks: Int
}

enum CombatEventType {
    case roll
    case damage
}

struct CombatEvent {
    let type: CombatEventType
    let actorName: String
    let cardName: String
    let dieIndex: Int
    let roll: Int?          // for .roll
    let hpDamage: Int?      // for .damage
    let staggerDamage: Int? // for .damage
}

struct Deck {
    var drawPile: [Card] = []
    
    // Changing 'from' to an 'inout' parameter allows this function
    // to modify the Nugget's actual deck and discard lists directly.
    mutating func drawCard(from deck: inout [Card], discard: inout [Card]) -> Card? {
        // Guard against an entirely empty deck setup
        if drawPile.isEmpty && deck.isEmpty && discard.isEmpty { return nil }
        
        if drawPile.isEmpty {
            // If draw pile is empty, recycle the discard pile back into the deck
            if deck.isEmpty {
                drawPile = discard.shuffled()
                discard.removeAll()
            } else {
                drawPile = deck.shuffled()
            }
        }
        
        // Remove and return the top card safely
        return drawPile.isEmpty ? nil : drawPile.removeFirst()
    }
}
