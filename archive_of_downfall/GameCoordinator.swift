//
//  GameCoordinator.swift
//  archive_of_downfall
//

import SwiftUI

enum GameScene {
    case dialogue
    case fight
}

struct GameCoordinator: View {
    @State private var scene: GameScene = .dialogue

    var body: some View {
        ZStack {
            switch scene {
            case .dialogue:
                VisualNovelTextBoxView { scene = .fight }
                    .transition(.opacity)
            case .fight:
                FightScreen(player: Nugget( name: "player", page: Page(30, 15, [SpeedDice(min: 1, max: 4)], 1.0, 1.5, 2.0, 1.0, 1.5, 2.0), hp: 30, stagger: 15, light: 3, maxLight: 3, deck: CardDatabase.starterDeck, hand: [], discard: [], statuses: []), enemy: Enemies.basic).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: scene)
    }
}
