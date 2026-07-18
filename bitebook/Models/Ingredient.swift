import Foundation
import SwiftData

enum UnitOfMeasurement: String, Codable, CaseIterable {
    case unit, standard
}

enum UnitFamily {
    case weight, volume
}

enum StandardUnit: String, Codable, CaseIterable {
    case gram, ounce, pound, cup, tablespoon, teaspoon, milliliter

    var family: UnitFamily {
        switch self {
        case .gram, .ounce, .pound: return .weight
        case .cup, .tablespoon, .teaspoon, .milliliter: return .volume
        }
    }

    // Conversion factor into the family's base unit (grams for weight, milliliters for volume).
    private var baseUnitConversionFactor: Double {
        switch self {
        case .gram: return 1
        case .ounce: return 28.3495
        case .pound: return 453.592
        case .milliliter: return 1
        case .teaspoon: return 4.92892
        case .tablespoon: return 14.7868
        case .cup: return 236.588
        }
    }

    // nil when `other` is in a different family (e.g. weight vs. volume) — those aren't
    // convertible without ingredient-specific density data this app doesn't model.
    func convert(_ quantity: Double, to other: StandardUnit) -> Double? {
        guard family == other.family else { return nil }
        return quantity * baseUnitConversionFactor / other.baseUnitConversionFactor
    }

    func label(for quantity: Double) -> String {
        quantity == 1 ? rawValue : rawValue + "s"
    }
}

@Model
final class Ingredient {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var unitOfMeasurementRaw: String
    var defaultStandardUnitRaw: String?

    var unitOfMeasurement: UnitOfMeasurement {
        get { UnitOfMeasurement(rawValue: unitOfMeasurementRaw) ?? .unit }
        set { unitOfMeasurementRaw = newValue.rawValue }
    }

    var defaultStandardUnit: StandardUnit? {
        get { defaultStandardUnitRaw.flatMap { StandardUnit(rawValue: $0) } }
        set { defaultStandardUnitRaw = newValue?.rawValue }
    }

    init(
        name: String,
        unitOfMeasurement: UnitOfMeasurement,
        defaultStandardUnit: StandardUnit? = nil
    ) {
        precondition(
            (unitOfMeasurement == .standard) == (defaultStandardUnit != nil),
            "defaultStandardUnit must be set if and only if unitOfMeasurement is .standard"
        )

        self.id = UUID()
        self.name = name
        self.unitOfMeasurementRaw = unitOfMeasurement.rawValue
        self.defaultStandardUnitRaw = defaultStandardUnit?.rawValue
    }

    // nil when this ingredient's own name doubles as the unit (unitOfMeasurement == .unit)
    func unitLabel(for quantity: Double) -> String? {
        guard unitOfMeasurement == .standard else { return nil }
        return defaultStandardUnit?.label(for: quantity)
    }
}

struct IngredientLibrary {
    static let defaultIngredients: [Ingredient] = [
        // Proteins
        Ingredient(
            name: "Chicken Breast", unitOfMeasurement: .standard, defaultStandardUnit: .pound),
        Ingredient(
            name: "Chicken Thigh", unitOfMeasurement: .standard, defaultStandardUnit: .pound),
        Ingredient(name: "Ground Beef", unitOfMeasurement: .standard, defaultStandardUnit: .pound),
        Ingredient(
            name: "Ground Turkey", unitOfMeasurement: .standard, defaultStandardUnit: .pound),
        Ingredient(name: "Pork Chop", unitOfMeasurement: .unit),
        Ingredient(name: "Bacon", unitOfMeasurement: .unit),
        Ingredient(name: "Salmon", unitOfMeasurement: .standard, defaultStandardUnit: .ounce),
        Ingredient(name: "Shrimp", unitOfMeasurement: .standard, defaultStandardUnit: .ounce),
        Ingredient(name: "Tofu", unitOfMeasurement: .standard, defaultStandardUnit: .ounce),
        Ingredient(name: "Egg", unitOfMeasurement: .unit),

        // Grains & Starches
        Ingredient(name: "Rice", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Quinoa", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Pasta", unitOfMeasurement: .standard, defaultStandardUnit: .ounce),
        Ingredient(name: "Bread", unitOfMeasurement: .unit),
        Ingredient(name: "Tortilla", unitOfMeasurement: .unit),
        Ingredient(name: "Potato", unitOfMeasurement: .unit),
        Ingredient(name: "Sweet Potato", unitOfMeasurement: .unit),
        Ingredient(name: "Oats", unitOfMeasurement: .standard, defaultStandardUnit: .cup),

        // Vegetables
        Ingredient(name: "Broccoli", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Carrot", unitOfMeasurement: .unit),
        Ingredient(name: "Onion", unitOfMeasurement: .unit),
        Ingredient(name: "Garlic", unitOfMeasurement: .unit),
        Ingredient(name: "Bell Pepper", unitOfMeasurement: .unit),
        Ingredient(name: "Spinach", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Lettuce", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Tomato", unitOfMeasurement: .unit),
        Ingredient(name: "Cucumber", unitOfMeasurement: .unit),
        Ingredient(name: "Zucchini", unitOfMeasurement: .unit),
        Ingredient(name: "Mushroom", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Celery", unitOfMeasurement: .unit),

        // Fruits
        Ingredient(name: "Apple", unitOfMeasurement: .unit),
        Ingredient(name: "Banana", unitOfMeasurement: .unit),
        Ingredient(name: "Lemon", unitOfMeasurement: .unit),
        Ingredient(name: "Avocado", unitOfMeasurement: .unit),

        // Dairy
        Ingredient(name: "Milk", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Butter", unitOfMeasurement: .standard, defaultStandardUnit: .tablespoon),
        Ingredient(name: "Cheddar Cheese", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(
            name: "Mozzarella Cheese", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(
            name: "Parmesan Cheese", unitOfMeasurement: .standard, defaultStandardUnit: .tablespoon),
        Ingredient(name: "Greek Yogurt", unitOfMeasurement: .standard, defaultStandardUnit: .cup),

        // Pantry
        Ingredient(
            name: "Olive Oil", unitOfMeasurement: .standard, defaultStandardUnit: .tablespoon),
        Ingredient(name: "Salt", unitOfMeasurement: .standard, defaultStandardUnit: .teaspoon),
        Ingredient(
            name: "Black Pepper", unitOfMeasurement: .standard, defaultStandardUnit: .teaspoon),
        Ingredient(
            name: "Soy Sauce", unitOfMeasurement: .standard, defaultStandardUnit: .tablespoon),
        Ingredient(name: "Flour", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Sugar", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Chicken Broth", unitOfMeasurement: .standard, defaultStandardUnit: .cup),
        Ingredient(name: "Canned Tomatoes", unitOfMeasurement: .unit),
        Ingredient(name: "Black Beans", unitOfMeasurement: .unit),
    ]
}
