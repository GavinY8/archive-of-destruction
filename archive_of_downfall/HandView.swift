//
//  HandView.swift
//  archive_of_downfall
//

import SwiftUI

struct HandView: View {
    let nugget: Nugget
    let assignedCardNames: Set<String>   // ← add this
    let onCardSelected: (Card) -> Void


    @State private var selectedIndex: Int? = nil
    @State private var appeared = false

    var displayableCards: [Card] {
        nugget.hand.filter { !assignedCardNames.contains($0.name) }
        // no longer filtering by cost here
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark parchment background
            Color(red: 0.08, green: 0.07, blue: 0.06)
                .ignoresSafeArea()

            // Light cost display
            VStack {
                HStack {
                    Spacer()
                    LightMeter(current: nugget.light, max: nugget.maxLight)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                }
                Spacer()
            }

            // Card fan
            ZStack {
                ForEach(Array(displayableCards.enumerated()), id: \.offset) { index, card in
                    let total = displayableCards.count
                    let mid = Double(total - 1) / 2.0
                    let offset = Double(index) - mid
                    let isSelected = selectedIndex == index
                    let isAffordable = card.cost <= nugget.light && !nugget.isStaggered

                    CardView(card: card, isSelected: isSelected, isAffordable: isAffordable)
                        .rotationEffect(.degrees(offset * 6))
                        .offset(
                            x: offset * 72,
                            y: isSelected ? -60 : (abs(offset) * 8)
                        )
                        .zIndex(isSelected ? 10 : Double(index))
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                        .onTapGesture {
                            if selectedIndex == index {
                                guard isAffordable else { return }  // block confirm, not selection
                                onCardSelected(card)
                                selectedIndex = nil
                            } else {
                                selectedIndex = index  // always allow selecting to inspect
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 80)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(Double(index) * 0.06),
                            value: appeared
                        )
                }
            }
            .padding(.bottom, 32)

            // Confirm button
            if let idx = selectedIndex {
                let card = displayableCards[idx]
                if card.cost <= nugget.light {          // ← add this guard
                    ConfirmButton(card: card) {
                        onCardSelected(card)
                        selectedIndex = nil
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Card View

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isAffordable: Bool

    var body: some View {
        ZStack {
            // Card body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.13, green: 0.11, blue: 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(isAffordable ? 0 : 0.45))
                )
                .shadow(color: isSelected ? Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.4) : .black.opacity(0.5), radius: isSelected ? 12 : 6)

            VStack(spacing: 6) {
                // Cost pip
                Text("\(card.cost)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(isAffordable ? Color(red: 0.95, green: 0.85, blue: 0.55) : .gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                Spacer()

                // Card name
                Text(card.name)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(isAffordable ? Color(red: 0.92, green: 0.88, blue: 0.8) : Color.gray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // Dice row
                HStack(spacing: 3) {
                    ForEach(Array(card.dice.enumerated()), id: \.offset) { _, die in
                        DicePip(die: die)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .frame(width: 90, height: 130)
        .opacity(isAffordable ? 1.0 : 0.45)
    }
}

// MARK: - Dice Pip

struct DicePip: View {
    let die: Dice

    var color: Color {
        switch die.type {
        case .atk:
            switch die.atkType {
            case .slash:  return Color(red: 0.85, green: 0.3, blue: 0.3)
            case .pierce: return Color(red: 0.35, green: 0.65, blue: 0.9)
            case .blunt:  return Color(red: 0.75, green: 0.5, blue: 0.2)
            case .none:   return .red
            }
        case .block: return Color(red: 0.4, green: 0.7, blue: 0.45)
        case .evade: return Color(red: 0.7, green: 0.55, blue: 0.85)
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("\(die.maxRoll)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(width: 18, height: 18)
        .background(color.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Light Meter

struct LightMeter: View {
    let current: Int
    let max: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max, id: \.self) { i in
                Circle()
                    .fill(i < current
                          ? Color(red: 0.95, green: 0.85, blue: 0.4)
                          : Color(red: 0.25, green: 0.22, blue: 0.18))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().strokeBorder(Color(red: 0.5, green: 0.45, blue: 0.35), lineWidth: 0.5)
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
    }
}

// MARK: - Confirm Button

struct ConfirmButton: View {
    let card: Card
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("PLAY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Text("·")
                Text(card.name)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
            }
            .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.06))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(red: 0.85, green: 0.75, blue: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .animation(.spring(response: 0.3), value: card.name)
    }
}
