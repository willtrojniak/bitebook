import SwiftData

@MainActor
final class IngredientLibraryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func search(_ query: String) -> [Ingredient] {
        []
    }
}
