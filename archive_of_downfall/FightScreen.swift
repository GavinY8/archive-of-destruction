//
//  FightScreen.swift
//  archive_of_downfall
//

import SwiftUI

// MARK: - Combat Phase

enum CombatPhase {
    case cardAssignment(slotIndex: Int)
    case confirmation
    case resolving
    case turnEnd
}

// MARK: - Fight Screen

struct FightScreen: View {
    @State var player: Nugget
    @State var enemy: Nugget
    @State var phase: CombatPhase = .cardAssignment(slotIndex: 0)
    @State var assignedCards: [Int: Card] = [:]
    @State var log: [String] = []
    @State private var combatEvents: [CombatEvent] = []
    @State private var currentEventIndex: Int = 0
    @State private var isReplayingEvents = false

    var totalSlots: Int { player.page.speedDice.count }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.07, green: 0.06, blue: 0.05).ignoresSafeArea()
            backgroundTexture

            VStack(spacing: 0) {
                // Top bar: enemy vs player info
                HStack(alignment: .top, spacing: 0) {
                    NuggetInfoPanel(nugget: enemy, flipped: true)
                    Spacer()
                    CombatLogPanel(entries: log)
                    Spacer()
                    NuggetInfoPanel(nugget: player, flipped: false)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(height: 160)

                Divider()
                    .background(Color(red: 0.35, green: 0.3, blue: 0.25))
                    .padding(.horizontal, 20)

                // Speed die slots
                SpeedSlotRow(
                    speedDice: player.page.speedDice,
                    assignedCards: assignedCards,
                    activeSlot: activeSlot
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .frame(height: 72)

                Divider()
                    .background(Color(red: 0.35, green: 0.3, blue: 0.25))
                    .padding(.horizontal, 20)

                // Bottom: hand or confirmation
                Group {
                    switch phase {
                    case .cardAssignment(let slotIndex):
                        ZStack(alignment: .bottomTrailing) {
                            HandView(
                                nugget: player,
                                assignedCardNames: Set(assignedCards.values.map(\.name)),
                                onCardSelected: { card in
                                    assignCard(card, toSlot: slotIndex)
                                }
                            )

                            Button {
                                endTurnWithoutMoreCards()
                            } label: {
                                Text("END TURN")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.06))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.7, green: 0.65, blue: 0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                        }
                    case .confirmation:
                        ConfirmationPanel(
                            assignedCards: assignedCards,
                            speedDice: player.page.speedDice
                        ) {
                            startResolution()
                        } onBack: {
                            // Go back to last unfilled slot
                            let lastSlot = totalSlots - 1
                            assignedCards.removeValue(forKey: lastSlot)
                            phase = .cardAssignment(slotIndex: lastSlot)
                        }
                    case .resolving:
                        ResolvingView()
                    case .turnEnd:
                        TurnEndView {
                            advanceTurn()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .onAppear {
                    drawCards(nugget: &player, count: 5)
                    drawCards(nugget: &enemy, count: 5)
                }
        }
    }

    // MARK: - Helpers

    var activeSlot: Int? {
        if case .cardAssignment(let i) = phase { return i }
        return nil
    }

    func assignCard(_ card: Card, toSlot slot: Int) {
        assignedCards[slot] = card
        // don't touch hand or light here

        let nextSlot = slot + 1
        if nextSlot < totalSlots {
            phase = .cardAssignment(slotIndex: nextSlot)
        } else {
            phase = .confirmation
        }
    }

    func startResolution() {
        // 1. Pay costs and remove cards from player hand
        for (_, card) in assignedCards {
            if let index = player.hand.firstIndex(where: { $0.id == card.id }) {
                player.hand.remove(at: index)
            }
            player.light -= card.cost
        }

        phase = .resolving
        combatEvents = []
        currentEventIndex = 0

        // 2. If enemy is staggered, they do nothing this turn
        if enemy.isStaggered {
            for (_, pCard) in assignedCards {
                // Resolve player cards as unopposed attacks
                unopposedAttack(attacker: &player, defender: &enemy, chosenCard: pCard)
                // If you want: add roll/damage events inside unopposedAttack or around it
            }

            Task {
                log.append("\(enemy.name) is staggered and cannot act.")
                try? await Task.sleep(nanoseconds: 400_000_000)
                turnEnd(player: &player, enemy: &enemy)
                phase = .turnEnd
            }
            return
        }

        // 3. Normal behavior when enemy NOT staggered...

        // Track which speed slots the enemy actually used
        var enemyPlayedSlots: Set<Int> = []

        // Enemy picks cards for each of their speed slots
        for slotIndex in 0..<enemy.page.speedDice.count {
            print("Slot", slotIndex, "enemy isStaggered:", enemy.isStaggered)

            guard let eCard = chooseCard(unit: &enemy, strategy: "highest_cost") else {
                print("Enemy has no card for slot", slotIndex)
                continue
            }

            enemyPlayedSlots.insert(slotIndex)

            if let pCard = assignedCards[slotIndex] {
                // Both sides have a card — clash
                clash(
                    player: &player,
                    enemy: &enemy,
                    playerCard: pCard,
                    enemyCard: eCard,
                    events: &combatEvents
                )
            } else {
                // Enemy unopposed with this card
                print("Enemy unopposed with \(eCard.name)")

                var tempE = enemy
                tempE.page.speedDice = [SpeedDice(min: 1, max: 1, assignedCard: eCard)]
                StatusManager.triggerAttackStartStatuses(on: &tempE)
                var processedCard = tempE.page.speedDice[0].assignedCard!

                while !processedCard.dice.isEmpty && !player.isStaggered {
                    let die = processedCard.dice.removeFirst()
                    let eRoll = roll(min: die.minRoll, max: die.maxRoll)

                    // Log the roll
                    combatEvents.append(
                        CombatEvent(
                            type: .roll,
                            actorName: enemy.name,
                            cardName: eCard.name,
                            dieIndex: 0,
                            roll: eRoll,
                            hpDamage: nil,
                            staggerDamage: nil
                        )
                    )

                    // Only attack if it's an attack die
                    if die.type == .atk {
                        let (hp, stg) = calculateDamage(
                            baseRoll: eRoll,
                            type: die.atkType,
                            target: player
                        )
                        attack(
                            attacker: &enemy,
                            defender: &player,
                            chosenDice: die,
                            diceRoll: eRoll
                        )

                        combatEvents.append(
                            CombatEvent(
                                type: .damage,
                                actorName: enemy.name,
                                cardName: eCard.name,
                                dieIndex: 0,
                                roll: nil,
                                hpDamage: hp,
                                staggerDamage: stg
                            )
                        )
                    }
                }
            }
        }

        // 4. Any player slots the enemy never matched → unopposed player attacks
        for (slotIndex, pCard) in assignedCards {
            if !enemyPlayedSlots.contains(slotIndex) {
                print("Player unopposed with \(pCard.name) at slot", slotIndex)
                unopposedAttack(attacker: &player, defender: &enemy, chosenCard: pCard)
                // Optional: if you want the same roll-by-roll events here,
                // you can mirror the enemy unopposed logic but for the player.
            }
        }

        // 5. Replay events one by one into the log
        Task {
            for i in 0..<combatEvents.count {
                currentEventIndex = i
                appendEventToLog(combatEvents[i])
                try? await Task.sleep(nanoseconds: 600_000_000)
            }
            isReplayingEvents = false
            turnEnd(player: &player, enemy: &enemy)
            phase = .turnEnd
        }
    }
    
    func appendEventToLog(_ event: CombatEvent) {
        switch event.type {
        case .roll:
            if let roll = event.roll {
                log.append("\(event.actorName) rolls \(roll) with \(event.cardName)")
            }
        case .damage:
            let hp = event.hpDamage ?? 0
            let stg = event.staggerDamage ?? 0
            log.append("\(event.actorName) deals \(hp) HP / \(stg) STG")
        }
    }

    func advanceTurn() {
        turnStart(player: &player, enemy: &enemy)
        assignedCards = [:]
        drawCards(nugget: &player, count: 1)  // or however many per turn
        phase = .cardAssignment(slotIndex: 0)
    }
    
    func endTurnWithoutMoreCards() {
        // Option A: still show the confirmation panel
        phase = .confirmation

        // Option B: skip confirmation and immediately resolve
        // startResolution()
    }

    // Subtle noise texture overlay
    var backgroundTexture: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.10, blue: 0.08).opacity(0.6),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
    }
}

// MARK: - Nugget Info Panel

struct NuggetInfoPanel: View {
    let nugget: Nugget
    let flipped: Bool

    var body: some View {
        VStack(alignment: flipped ? .leading : .trailing, spacing: 6) {
            Text(nugget.name)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.92, green: 0.88, blue: 0.78))

            // HP bar
            StatBar(
                label: "HP",
                current: nugget.hp,
                max: nugget.page.maxhp,
                color: Color(red: 0.75, green: 0.25, blue: 0.25),
                flipped: flipped
            )

            // Stagger bar
            StatBar(
                label: "STG",
                current: nugget.stagger,
                max: nugget.page.maxStagger,
                color: Color(red: 0.8, green: 0.65, blue: 0.2),
                flipped: flipped
            )

            // Statuses
            if !nugget.statuses.isEmpty {
                HStack(spacing: 4) {
                    ForEach(nugget.statuses, id: \.type) { status in
                        StatusPip(status: status)
                    }
                }
            }

            // Staggered indicator
            if nugget.isStaggered {
                Text("STAGGERED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.2))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(red: 0.3, green: 0.25, blue: 0.2), lineWidth: 1)
        )
    }
}

// MARK: - Stat Bar

struct StatBar: View {
    let label: String
    let current: Int
    let max: Int
    let color: Color
    let flipped: Bool

    var fraction: CGFloat { max > 0 ? CGFloat(current) / CGFloat(max) : 0 }

    var body: some View {
        HStack(spacing: 6) {
            if flipped {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 28, alignment: .leading)
            }

            GeometryReader { geo in
                ZStack(alignment: flipped ? .leading : .trailing) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * fraction)
                        .animation(.spring(response: 0.4), value: fraction)
                }
            }
            .frame(width: 100, height: 6)

            if !flipped {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 28, alignment: .trailing)
            }

            Text("\(current)/\(max)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
        }
    }
}

// MARK: - Status Pip

struct StatusPip: View {
    let status: Status

    var color: Color {
        switch status.type {
        case .bleed:             return Color(red: 0.8, green: 0.15, blue: 0.15)
        case .burn:              return Color(red: 0.9, green: 0.45, blue: 0.1)
        case .paralysis:         return Color(red: 0.7, green: 0.7, blue: 0.2)
        case .protection:        return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .staggerProtection: return Color(red: 0.5, green: 0.8, blue: 0.5)
        case .fragile:           return Color(red: 0.8, green: 0.4, blue: 0.7)
        case .strength:          return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .feeble:            return Color(red: 0.5, green: 0.4, blue: 0.6)
        case .endurance:         return Color(red: 0.4, green: 0.7, blue: 0.5)
        case .disarm:            return Color(red: 0.7, green: 0.3, blue: 0.3)
        case .haste:             return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .bind:              return Color(red: 0.5, green: 0.35, blue: 0.2)
        }
    }

    var label: String {
        switch status.type {
        case .bleed:             return "BLD"
        case .burn:              return "BRN"
        case .paralysis:         return "PAR"
        case .protection:        return "PRO"
        case .staggerProtection: return "SPR"
        case .fragile:           return "FRG"
        case .strength:          return "STR"
        case .feeble:            return "FBL"
        case .endurance:         return "END"
        case .disarm:            return "DIS"
        case .haste:             return "HST"
        case .bind:              return "BND"
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("\(status.stacks)")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color.opacity(0.5), lineWidth: 0.5))
    }
}

// MARK: - Speed Slot Row

struct SpeedSlotRow: View {
    let speedDice: [SpeedDice]
    let assignedCards: [Int: Card]
    let activeSlot: Int?

    var body: some View {
        HStack(spacing: 12) {
            Text("SPEED SLOTS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

            ForEach(Array(speedDice.enumerated()), id: \.offset) { index, die in
                SpeedSlotView(
                    die: die,
                    assignedCard: assignedCards[index],
                    isActive: activeSlot == index,
                    index: index
                )
            }
            Spacer()
        }
    }
}

// MARK: - Speed Slot View

struct SpeedSlotView: View {
    let die: SpeedDice
    let assignedCard: Card?
    let isActive: Bool
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            // Die range label
            VStack(spacing: 1) {
                Text("\(die.min)–\(die.max)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                Text("SPD")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .frame(width: 32)

            // Card slot
            RoundedRectangle(cornerRadius: 6)
                .fill(assignedCard != nil
                      ? Color(red: 0.15, green: 0.13, blue: 0.1)
                      : Color.black.opacity(0.3))
                .overlay(
                    Group {
                        if let card = assignedCard {
                            Text(card.name)
                                .font(.system(size: 9, weight: .semibold, design: .serif))
                                .foregroundColor(Color(red: 0.92, green: 0.88, blue: 0.78))
                                .padding(4)
                        } else {
                            Text(isActive ? "SELECT" : "—")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(isActive
                                                 ? Color(red: 0.85, green: 0.75, blue: 0.5)
                                                 : Color(red: 0.35, green: 0.3, blue: 0.25))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isActive
                                ? Color(red: 0.85, green: 0.75, blue: 0.5)
                                : Color(red: 0.3, green: 0.25, blue: 0.2),
                            lineWidth: isActive ? 1.5 : 1
                        )
                )
                .frame(width: 90, height: 40)
                .shadow(color: isActive ? Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.3) : .clear, radius: 6)
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(isActive ? 0.4 : 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isActive
                        ? Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.4)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Combat Log

struct CombatLogPanel: View {
    let entries: [String]

    var body: some View {
        VStack(spacing: 4) {
            Text("COMBAT LOG")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entries.suffix(6).reversed(), id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(red: 0.65, green: 0.6, blue: 0.55))
                    }
                }
            }
        }
        .frame(width: 180, height: 120)
        .padding(8)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(red: 0.3, green: 0.25, blue: 0.2), lineWidth: 1))
    }
}

// MARK: - Confirmation Panel

struct ConfirmationPanel: View {
    let assignedCards: [Int: Card]
    let speedDice: [SpeedDice]
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("READY TO CLASH")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))

            HStack(spacing: 16) {
                ForEach(Array(speedDice.enumerated()), id: \.offset) { index, die in
                    if let card = assignedCards[index] {
                        VStack(spacing: 4) {
                            Text("\(die.min)–\(die.max)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
                            Text(card.name)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundColor(Color(red: 0.92, green: 0.88, blue: 0.78))
                            Text("Cost: \(card.cost)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(red: 0.4, green: 0.35, blue: 0.3), lineWidth: 1))
                    }
                }
            }

            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("← BACK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(red: 0.35, green: 0.3, blue: 0.25), lineWidth: 1))
                }

                Button(action: onConfirm) {
                    Text("BEGIN CLASH")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.06))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.85, green: 0.75, blue: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Resolving / Turn End placeholders

struct ResolvingView: View {
    var body: some View {
        Text("RESOLVING...")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TurnEndView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("TURN END")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.45))
            Button(action: onNext) {
                Text("NEXT TURN →")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.06))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.85, green: 0.75, blue: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview(traits: .landscapeLeft) {
    FightScreen(player: Nugget( name: "player", page: Page(30, 15, [SpeedDice(min: 1, max: 4)], 1.0, 1.5, 2.0, 1.0, 1.5, 2.0), hp: 30, stagger: 15, light: 3, maxLight: 3, deck: CardDatabase.starterDeck, hand: [], discard: [], statuses: []), enemy: Nugget( name: "enemy", page: Page(30, 15, [SpeedDice(min: 1, max: 4), SpeedDice(min: 2, max: 5)], 1.0, 1.5, 2.0, 1.0, 1.5, 2.0), hp: 30, stagger: 15, light: 3, maxLight: 3, deck: CardDatabase.starterDeck, hand: [], discard: [], statuses: []))
    
}
