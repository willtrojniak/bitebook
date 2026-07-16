import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Query(sort: \Recipe.name)
    private var recipes: [Recipe]

    var body: some View {
        List(recipes) { recipe in
            Text(recipe.name)
        }
        .navigationTitle("Recipes")
    }
}
