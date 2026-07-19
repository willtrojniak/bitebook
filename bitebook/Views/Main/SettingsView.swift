import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    IngredientLibraryView()
                } label: {
                    Label("Ingredients", systemImage: "carrot")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
