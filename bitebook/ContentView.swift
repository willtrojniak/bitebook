//
//  ContentView.swift
//  bitebook
//
//  Created by Will Trojniak on 7/11/26.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab: Tab = .plan

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            Group {
                switch selectedTab {
                case .plan:
                    PlannerView()
                case .shopping:
                    ShoppingView()
                case .recipes:
                    RecipesView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            TabsView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
}
