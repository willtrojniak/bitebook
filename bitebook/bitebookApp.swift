//
//  bitebookApp.swift
//  bitebook
//
//  Created by Will Trojniak on 7/11/26.
//

import SwiftData
import SwiftUI

@main
struct bitebookApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Ingredient.self,
            Recipe.self,
            RecipeIngredient.self,
        ])

        do {
            container = try ModelContainer(
                for: schema
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    seedIngredients()
                }
        }
    }

    private func seedIngredients() {
        let context = container.mainContext

        let existingIngredients =
            (try? context.fetch(FetchDescriptor<Ingredient>())) ?? []
        let existingNames = Set(existingIngredients.map { $0.name })

        let newIngredients = IngredientLibrary.defaultIngredients.filter {
            !existingNames.contains($0.name)
        }

        guard !newIngredients.isEmpty else {
            return
        }

        for ingredient in newIngredients {
            context.insert(ingredient)
        }

        try? context.save()
    }
}
