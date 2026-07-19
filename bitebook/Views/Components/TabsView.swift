import SwiftUI

enum Tab {
    case plan
    case shopping
    case recipes
    case settings
}

struct TabsView: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            TabButton(
                title: "Planner",
                systemImage: "stove",
                selected: selectedTab == .plan
            ) {
                selectedTab = .plan
            }

            TabButton(
                title: "Shopping",
                systemImage: "cart",
                selected: selectedTab == .shopping
            ) {
                selectedTab = .shopping
            }

            TabButton(
                title: "Recipes",
                systemImage: "book.pages",
                selected: selectedTab == .recipes
            ) {
                selectedTab = .recipes
            }

            TabButton(
                title: "Settings",
                systemImage: "gearshape",
                selected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)

    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))

                Text(title)
                    .font(.caption)
            }
            .frame(width: 80)
            .foregroundStyle(selected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
