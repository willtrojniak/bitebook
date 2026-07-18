import SwiftData
import SwiftUI

struct MealEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(MealClipboard.self) private var clipboard

    let date: Date
    let mealType: MealType

    @Query(sort: \Recipe.name)
    private var allRecipes: [Recipe]

    @Query private var plannedMeals: [PlannedMeal]

    @State private var showingRecipePicker = false

    init(date: Date, mealType: MealType) {
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType

        _plannedMeals = Query(filter: PlannedMeal.matching(date: date, mealType: mealType))
    }

    private var assignedRecipes: [Recipe] {
        plannedMeals.map { $0.recipe }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(mealType.rawValue)
                    .font(.title2)
                    .bold()

                Text(date.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recipes")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        clipboard.copy(from: date, mealType: mealType, modelContext: modelContext)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Copy Recipes")

                    Button {
                        clipboard.paste(to: date, mealType: mealType, modelContext: modelContext)
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!clipboard.canPaste)
                    .accessibilityLabel("Paste Recipes")

                    Button {
                        showingRecipePicker = true
                    } label: {
                        Label("Add Recipe", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $showingRecipePicker, arrowEdge: .top) {
                        RecipePickerView(
                            recipes: allRecipes,
                            selectedRecipeIDs: Set(assignedRecipes.map { $0.id })
                        ) { recipe in
                            MealPlanService(modelContext: modelContext)
                                .addRecipe(recipe, to: date, mealType: mealType)
                        }
                        .frame(width: 280, height: 320)
                    }
                }

                if assignedRecipes.isEmpty {
                    Text("No recipes added yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                } else {
                    List {
                        ForEach(assignedRecipes) { recipe in
                            HStack(spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)

                                Text(recipe.name)

                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .padding(.trailing, 8)
                            .swipeActions {
                                Button("Remove", systemImage: "trash", role: .destructive) {
                                    MealPlanService(modelContext: modelContext)
                                        .removeRecipe(recipe, from: date, mealType: mealType)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480, height: 480, alignment: .top)
    }
}
