//
//  MainScreen.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//

import SwiftUI

struct StartScreen: View {
    var body: some View {
        ZStack {
            Image("StartScreen Background")
                .resizable()
                .ignoresSafeArea()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    StartScreen()
}
