import Foundation
import SwiftData

// Narrow, family-scoped unit enums used only for specifying an ingredient's default
// measurement (see IngredientMeasurement) — this is what makes an invalid pairing like
// "standardMass, default: .milliliter" impossible to write, not just checked at runtime.
enum MassUnit: String, Codable, CaseIterable {
    case gram, ounce, pound

    var factor: Double {
        switch self {
        case .gram: return 1.0
        case .ounce: return 28.3495
        case .pound: return 453.592
        }
    }

    func label(for quantity: Double) -> String {
        return quantity == 1 ? self.rawValue : self.rawValue + "s"
    }
}

enum VolumeUnit: String, Codable, CaseIterable {
    case cup, tablespoon, teaspoon, milliliter

    var factor: Double {
        switch self {
        case .cup: return 236.588
        case .tablespoon: return 14.78675
        case .teaspoon: return 4.9289
        case .milliliter: return 1.0
        }
    }

    func label(for quantity: Double) -> String {
        return quantity == 1 ? self.rawValue : self.rawValue + "s"
    }
}

enum UnitOfMeasurement: Codable, Hashable {
    case unit
    case standardMass(unit: MassUnit)
    case standardVolume(unit: VolumeUnit)

    func label(for quantity: Double) -> String {
        switch self {
        case .unit:
            return quantity == 1 ? "unit" : "units"
        case .standardMass(let unit):
            return unit.label(for: quantity)
        case .standardVolume(let unit):
            return unit.label(for: quantity)
        }
    }
}

// The only way to specify how an ingredient is measured. Each case carries exactly the
// data valid for it, so a mismatched combination (e.g. a mass ingredient with a volume
// default unit) can't be constructed at all.
enum IngredientMeasurement {
    case unit(unitToMass: Double? = nil, unitToVolume: Double? = nil)
    case standardMass(default: MassUnit)
    case standardVolume(default: VolumeUnit)
}

@Model
final class Ingredient {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var defaultUnitOfMeasurement: UnitOfMeasurement
    private var unitToMassConversionFactor: Double?
    private var unitToVolumeConversionFactor: Double?

    // Read-only public access to the two private factors above, for UI that needs to
    // display/prefill them (e.g. an ingredient editor) without exposing direct mutation.
    var unitToMass: Double? { unitToMassConversionFactor }
    var unitToVolume: Double? { unitToVolumeConversionFactor }

    init(name: String, measurement: IngredientMeasurement) {
        self.id = UUID()
        self.name = name

        switch measurement {
        case (.unit(unitToMass: let toMass, unitToVolume: let toVolume)):
            self.defaultUnitOfMeasurement = .unit
            self.unitToMassConversionFactor = toMass
            self.unitToVolumeConversionFactor = toVolume
        case (.standardMass(default: let defaultMassUnit)):
            self.defaultUnitOfMeasurement = .standardMass(unit: defaultMassUnit)
        case (.standardVolume(default: let defaultVolumeUnit)):
            self.defaultUnitOfMeasurement = .standardVolume(unit: defaultVolumeUnit)
        }
    }

    func update(name: String, measurement: IngredientMeasurement) {
        self.name = name

        switch measurement {
        case (.unit(unitToMass: let toMass, unitToVolume: let toVolume)):
            self.defaultUnitOfMeasurement = .unit
            self.unitToMassConversionFactor = toMass
            self.unitToVolumeConversionFactor = toVolume
        case (.standardMass(default: let defaultMassUnit)):
            self.defaultUnitOfMeasurement = .standardMass(unit: defaultMassUnit)
            self.unitToMassConversionFactor = nil
            self.unitToVolumeConversionFactor = nil
        case (.standardVolume(default: let defaultVolumeUnit)):
            self.defaultUnitOfMeasurement = .standardVolume(unit: defaultVolumeUnit)
            self.unitToMassConversionFactor = nil
            self.unitToVolumeConversionFactor = nil
        }
    }

    var measurementSummary: String {
        switch defaultUnitOfMeasurement {
        case .standardMass(let unit):
            return "Standard · \(unit.rawValue)"
        case .standardVolume(let unit):
            return "Standard · \(unit.rawValue)"
        case .unit:
            if let mass = unitToMassConversionFactor {
                return "Counted individually · ≈\(mass.formatted())g each"
            }
            if let volume = unitToVolumeConversionFactor {
                return "Counted individually · ≈\(volume.formatted())mL each"
            }
            return "Counted individually"
        }
    }

    private func conversionFactor(from unit: UnitOfMeasurement, to targetUnit: UnitOfMeasurement)
        -> Double?
    {
        switch (unit, targetUnit) {
        case (.unit, .unit):
            return 1.0
        case (.standardMass(unit: let fromUnit), .standardMass(unit: let toUnit)):
            return fromUnit.factor / toUnit.factor
        case (.standardVolume(unit: let fromUnit), .standardVolume(unit: let toUnit)):
            return fromUnit.factor / toUnit.factor
        case (.unit, .standardMass(unit: let toUnit)):
            guard let f = self.unitToMassConversionFactor else { return nil }
            return f / toUnit.factor
        case (.standardMass(unit: let toUnit), .unit):
            guard let f = self.unitToMassConversionFactor else { return nil }
            return toUnit.factor / f
        case (.unit, .standardVolume(unit: let toUnit)):
            guard let f = self.unitToVolumeConversionFactor else { return nil }
            return f / toUnit.factor
        case (.standardVolume(unit: let toUnit), .unit):
            guard let f = self.unitToVolumeConversionFactor else { return nil }
            return toUnit.factor / f
        case (.standardVolume, .standardMass), (.standardMass, .standardVolume):
            guard let toUnit = conversionFactor(from: unit, to: .unit) else { return nil }
            guard let toTarget = conversionFactor(from: .unit, to: targetUnit) else { return nil }
            return toUnit * toTarget
        }
    }

    // Converts a RecipeIngredient's recorded quantity from `unit` to `targetUnit`.
    // Returns nil if the requested unit isn't available for this ingredient (e.g. a mass unit
    // requested for an ingredient with no unitToMass).
    func convertQuantity(
        _ quantity: Double, from unit: UnitOfMeasurement, to targetUnit: UnitOfMeasurement
    )
        -> Double?
    {
        guard let factor = self.conversionFactor(from: unit, to: targetUnit) else { return nil }
        return quantity * factor
    }

    /// Formats an already-aggregated `quantity` (expressed in this ingredient's "default"
    /// — UnitOfMeasurement) as a friendly display string.
    func formattedQuantity(_ quantity: Double) -> String {
        func format(_ amount: Double, _ unit: UnitOfMeasurement) -> String {
            "\(amount.formatted(.number.precision(.fractionLength(0...3)))) \(unit.label(for: amount))"
        }
        return "\(format(quantity, defaultUnitOfMeasurement))"
    }

    var validUnitsOfMeasurement: [UnitOfMeasurement] {
        var units: [UnitOfMeasurement] = []
        if self.conversionFactor(from: self.defaultUnitOfMeasurement, to: .unit) != nil {
            units.append(.unit)
        }

        if self.conversionFactor(
            from: self.defaultUnitOfMeasurement, to: .standardMass(unit: .gram)) != nil
        {
            units += MassUnit.allCases.map { .standardMass(unit: $0) }
        }

        if self.conversionFactor(
            from: self.defaultUnitOfMeasurement, to: .standardVolume(unit: .milliliter)) != nil
        {
            units += VolumeUnit.allCases.map { .standardVolume(unit: $0) }
        }

        return units

    }
}

struct IngredientLibrary {
    static let defaultIngredients: [Ingredient] = [
        // Proteins — Meat & Poultry
        Ingredient(name: "Chicken Breast", measurement: .unit(unitToMass: 200)),
        Ingredient(name: "Chicken Thigh", measurement: .unit(unitToMass: 180)),
        Ingredient(name: "Chicken Drumstick", measurement: .unit(unitToMass: 80)),
        Ingredient(name: "Chicken Wing", measurement: .unit(unitToMass: 80)),
        Ingredient(name: "Whole Chicken", measurement: .unit()),
        Ingredient(name: "Ground Chicken", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Chicken Tenderloin", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Rotisserie Chicken", measurement: .unit()),
        Ingredient(name: "Turkey Breast", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Ground Turkey", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Turkey Bacon", measurement: .unit()),
        Ingredient(name: "Turkey Sausage", measurement: .unit()),
        Ingredient(name: "Ground Beef", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Beef Sirloin", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Ribeye Steak", measurement: .unit()),
        Ingredient(name: "Beef Tenderloin", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Flank Steak", measurement: .unit()),
        Ingredient(name: "Skirt Steak", measurement: .unit()),
        Ingredient(name: "Short Ribs", measurement: .standardMass(default: .pound)),
        Ingredient(name: "New York Strip Steak", measurement: .unit()),
        Ingredient(name: "Filet Mignon", measurement: .unit()),
        Ingredient(name: "Pork Chop", measurement: .unit()),
        Ingredient(name: "Pork Tenderloin", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Pork Shoulder", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Pork Belly", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Ground Pork", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Bacon", measurement: .unit()),
        Ingredient(name: "Canadian Bacon", measurement: .unit()),
        Ingredient(name: "Ham", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Deli Ham", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Sausage", measurement: .unit()),
        Ingredient(name: "Italian Sausage", measurement: .unit()),
        Ingredient(name: "Chorizo", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Pepperoni", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Prosciutto", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Salami", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Lamb Chop", measurement: .unit()),
        Ingredient(name: "Ground Lamb", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Leg of Lamb", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Veal Cutlet", measurement: .unit()),
        Ingredient(name: "Duck Breast", measurement: .unit()),
        Ingredient(name: "Venison", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Hot Dog", measurement: .unit()),
        Ingredient(name: "Deli Turkey", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Meatballs", measurement: .unit()),

        // Proteins — Seafood
        Ingredient(name: "Salmon", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Smoked Salmon", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Canned Tuna", measurement: .unit()),
        Ingredient(name: "Shrimp", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Scallops", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Cod", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Tilapia", measurement: .unit()),
        Ingredient(name: "Halibut", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Mahi Mahi", measurement: .unit()),
        Ingredient(name: "Crab Meat", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Crab Legs", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Lobster", measurement: .unit()),
        Ingredient(name: "Mussels", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Clams", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Oysters", measurement: .unit()),
        Ingredient(name: "Catfish", measurement: .unit()),
        Ingredient(name: "Trout", measurement: .unit()),
        Ingredient(name: "Sardines", measurement: .unit()),
        Ingredient(name: "Anchovies", measurement: .unit()),
        Ingredient(name: "Anchovy Paste", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Calamari", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Swordfish", measurement: .unit()),
        Ingredient(name: "Red Snapper", measurement: .unit()),
        Ingredient(name: "Sea Bass", measurement: .unit()),
        Ingredient(name: "Imitation Crab", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Fish Fillet", measurement: .unit()),
        Ingredient(name: "Crawfish", measurement: .standardMass(default: .pound)),

        // Proteins — Eggs & Plant-Based
        Ingredient(name: "Egg", measurement: .unit()),
        Ingredient(name: "Egg White", measurement: .unit()),
        Ingredient(name: "Egg Yolk", measurement: .unit()),
        Ingredient(name: "Tofu", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Firm Tofu", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Silken Tofu", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Tempeh", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Seitan", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Edamame", measurement: .standardVolume(default: .cup)),

        // Dairy & Cheese
        Ingredient(name: "Whole Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Skim Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "2% Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Almond Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Oat Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Soy Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Coconut Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Heavy Cream", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Half and Half", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sour Cream", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Buttermilk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Butter", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Unsalted Butter", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Margarine", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Whipped Cream", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Plain Yogurt", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Greek Yogurt", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cottage Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cream Cheese", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Ricotta Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Mascarpone", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cheddar Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Mozzarella Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Parmesan Cheese", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Swiss Cheese", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Feta Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Goat Cheese", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Blue Cheese", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Provolone", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Monterey Jack Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Gouda", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Brie", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "American Cheese", measurement: .unit()),
        Ingredient(name: "Queso Fresco", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "String Cheese", measurement: .unit()),
        Ingredient(name: "Condensed Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Evaporated Milk", measurement: .standardVolume(default: .cup)),

        // Grains, Pasta & Bread
        Ingredient(name: "White Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Brown Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Jasmine Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Basmati Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Arborio Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Wild Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sushi Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Quinoa", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Couscous", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Barley", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Farro", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Bulgur", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Polenta", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cornmeal", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Grits", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Rolled Oats", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Steel Cut Oats", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Spaghetti", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Penne", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Fettuccine", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Linguine", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Rigatoni", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Fusilli", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Macaroni", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Lasagna Noodles", measurement: .unit()),
        Ingredient(name: "Angel Hair Pasta", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Orzo", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Ravioli", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Tortellini", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Egg Noodles", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Rice Noodles", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Udon Noodles", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Soba Noodles", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Ramen Noodles", measurement: .unit()),
        Ingredient(name: "Bread", measurement: .unit()),
        Ingredient(name: "White Bread", measurement: .unit()),
        Ingredient(name: "Whole Wheat Bread", measurement: .unit()),
        Ingredient(name: "Sourdough Bread", measurement: .unit()),
        Ingredient(name: "Baguette", measurement: .unit()),
        Ingredient(name: "Pita Bread", measurement: .unit()),
        Ingredient(name: "Naan", measurement: .unit()),
        Ingredient(name: "Flour Tortilla", measurement: .unit()),
        Ingredient(name: "Corn Tortilla", measurement: .unit()),
        Ingredient(name: "Bagel", measurement: .unit()),
        Ingredient(name: "English Muffin", measurement: .unit()),
        Ingredient(name: "Dinner Roll", measurement: .unit()),
        Ingredient(name: "Hamburger Bun", measurement: .unit()),
        Ingredient(name: "Hot Dog Bun", measurement: .unit()),
        Ingredient(name: "Breadcrumbs", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Panko Breadcrumbs", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Croutons", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pizza Dough", measurement: .unit()),
        Ingredient(name: "Cornbread", measurement: .unit()),
        Ingredient(name: "Crescent Roll Dough", measurement: .unit()),
        Ingredient(name: "Biscuit Dough", measurement: .unit()),
        Ingredient(name: "Wonton Wrappers", measurement: .unit()),

        // Vegetables
        Ingredient(name: "Potato", measurement: .unit()),
        Ingredient(name: "Russet Potato", measurement: .unit()),
        Ingredient(name: "Yukon Gold Potato", measurement: .unit()),
        Ingredient(name: "Red Potato", measurement: .unit()),
        Ingredient(name: "Sweet Potato", measurement: .unit()),
        Ingredient(name: "Baby Potato", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Carrot", measurement: .unit()),
        Ingredient(name: "Baby Carrot", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Celery", measurement: .unit()),
        Ingredient(name: "Onion", measurement: .unit()),
        Ingredient(name: "Red Onion", measurement: .unit()),
        Ingredient(name: "Yellow Onion", measurement: .unit()),
        Ingredient(name: "White Onion", measurement: .unit()),
        Ingredient(name: "Green Onion", measurement: .unit()),
        Ingredient(name: "Shallot", measurement: .unit()),
        Ingredient(name: "Garlic", measurement: .unit()),
        Ingredient(name: "Garlic Clove", measurement: .unit()),
        Ingredient(name: "Bell Pepper", measurement: .unit()),
        Ingredient(name: "Red Bell Pepper", measurement: .unit()),
        Ingredient(name: "Green Bell Pepper", measurement: .unit()),
        Ingredient(name: "Yellow Bell Pepper", measurement: .unit()),
        Ingredient(name: "Jalapeño", measurement: .unit()),
        Ingredient(name: "Serrano Pepper", measurement: .unit()),
        Ingredient(name: "Poblano Pepper", measurement: .unit()),
        Ingredient(name: "Habanero Pepper", measurement: .unit()),
        Ingredient(name: "Banana Pepper", measurement: .unit()),
        Ingredient(name: "Tomato", measurement: .unit()),
        Ingredient(name: "Cherry Tomato", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Roma Tomato", measurement: .unit()),
        Ingredient(name: "Beefsteak Tomato", measurement: .unit()),
        Ingredient(name: "Broccoli", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Broccolini", measurement: .unit()),
        Ingredient(name: "Cauliflower", measurement: .unit()),
        Ingredient(name: "Brussels Sprouts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cabbage", measurement: .unit()),
        Ingredient(name: "Red Cabbage", measurement: .unit()),
        Ingredient(name: "Napa Cabbage", measurement: .unit()),
        Ingredient(name: "Spinach", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Baby Spinach", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Kale", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Lettuce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Romaine Lettuce", measurement: .unit()),
        Ingredient(name: "Iceberg Lettuce", measurement: .unit()),
        Ingredient(name: "Arugula", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Swiss Chard", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Collard Greens", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Zucchini", measurement: .unit()),
        Ingredient(name: "Yellow Squash", measurement: .unit()),
        Ingredient(name: "Butternut Squash", measurement: .unit()),
        Ingredient(name: "Acorn Squash", measurement: .unit()),
        Ingredient(name: "Spaghetti Squash", measurement: .unit()),
        Ingredient(name: "Pumpkin", measurement: .unit()),
        Ingredient(name: "Pumpkin Puree", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cucumber", measurement: .unit()),
        Ingredient(name: "Eggplant", measurement: .unit()),
        Ingredient(name: "Mushroom", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cremini Mushroom", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Portobello Mushroom", measurement: .unit()),
        Ingredient(name: "Shiitake Mushroom", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "White Mushroom", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Corn", measurement: .unit()),
        Ingredient(name: "Corn Kernels", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Green Beans", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Peas", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Snap Peas", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Snow Peas", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Asparagus", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Artichoke", measurement: .unit()),
        Ingredient(name: "Artichoke Heart", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Beet", measurement: .unit()),
        Ingredient(name: "Radish", measurement: .unit()),
        Ingredient(name: "Turnip", measurement: .unit()),
        Ingredient(name: "Parsnip", measurement: .unit()),
        Ingredient(name: "Leek", measurement: .unit()),
        Ingredient(name: "Fennel Bulb", measurement: .unit()),
        Ingredient(name: "Okra", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Avocado", measurement: .unit()),
        Ingredient(name: "Bok Choy", measurement: .unit()),
        Ingredient(name: "Bean Sprouts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Water Chestnuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Bamboo Shoots", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sun-Dried Tomato", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Capers", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Black Olives", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Green Olives", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Kalamata Olives", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pickle", measurement: .unit()),
        Ingredient(name: "Pickled Jalapeño", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Ginger Root", measurement: .unit()),

        // Fruits
        Ingredient(name: "Apple", measurement: .unit()),
        Ingredient(name: "Granny Smith Apple", measurement: .unit()),
        Ingredient(name: "Banana", measurement: .unit()),
        Ingredient(name: "Orange", measurement: .unit()),
        Ingredient(name: "Lemon", measurement: .unit()),
        Ingredient(name: "Lime", measurement: .unit()),
        Ingredient(name: "Grapefruit", measurement: .unit()),
        Ingredient(name: "Grape", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Strawberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Blueberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Raspberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Blackberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cranberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Dried Cranberry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pineapple", measurement: .unit()),
        Ingredient(name: "Mango", measurement: .unit()),
        Ingredient(name: "Papaya", measurement: .unit()),
        Ingredient(name: "Peach", measurement: .unit()),
        Ingredient(name: "Pear", measurement: .unit()),
        Ingredient(name: "Plum", measurement: .unit()),
        Ingredient(name: "Apricot", measurement: .unit()),
        Ingredient(name: "Dried Apricot", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cherry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Maraschino Cherry", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Watermelon", measurement: .unit()),
        Ingredient(name: "Cantaloupe", measurement: .unit()),
        Ingredient(name: "Honeydew Melon", measurement: .unit()),
        Ingredient(name: "Kiwi", measurement: .unit()),
        Ingredient(name: "Pomegranate", measurement: .unit()),
        Ingredient(name: "Pomegranate Seeds", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Fig", measurement: .unit()),
        Ingredient(name: "Dried Fig", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Date", measurement: .unit()),
        Ingredient(name: "Raisin", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Coconut", measurement: .unit()),
        Ingredient(name: "Shredded Coconut", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Coconut Flakes", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Passion Fruit", measurement: .unit()),
        Ingredient(name: "Guava", measurement: .unit()),
        Ingredient(name: "Persimmon", measurement: .unit()),
        Ingredient(name: "Nectarine", measurement: .unit()),
        Ingredient(name: "Clementine", measurement: .unit()),
        Ingredient(name: "Tangerine", measurement: .unit()),
        Ingredient(name: "Star Fruit", measurement: .unit()),
        Ingredient(name: "Dragon Fruit", measurement: .unit()),

        // Herbs & Spices
        Ingredient(name: "Basil", measurement: .unit()),
        Ingredient(name: "Dried Basil", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Parsley", measurement: .unit()),
        Ingredient(name: "Cilantro", measurement: .unit()),
        Ingredient(name: "Mint", measurement: .unit()),
        Ingredient(name: "Dill", measurement: .unit()),
        Ingredient(name: "Rosemary", measurement: .unit()),
        Ingredient(name: "Dried Rosemary", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Thyme", measurement: .unit()),
        Ingredient(name: "Dried Thyme", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Oregano", measurement: .unit()),
        Ingredient(name: "Dried Oregano", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sage", measurement: .unit()),
        Ingredient(name: "Tarragon", measurement: .unit()),
        Ingredient(name: "Chives", measurement: .unit()),
        Ingredient(name: "Bay Leaf", measurement: .unit()),
        Ingredient(name: "Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Kosher Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sea Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Black Pepper", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "White Pepper", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Red Pepper Flakes", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Cayenne Pepper", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Paprika", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Smoked Paprika", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Cumin Seed", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Ground Cumin", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Coriander Seed", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Ground Coriander", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Chili Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Garlic Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Onion Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Ground Ginger", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Ground Cinnamon", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Cinnamon Stick", measurement: .unit()),
        Ingredient(name: "Nutmeg", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Cloves", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Allspice", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Cardamom", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Star Anise", measurement: .unit()),
        Ingredient(name: "Fennel Seed", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Mustard Seed", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Curry Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Garam Masala", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Italian Seasoning", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Herbes de Provence", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Old Bay Seasoning", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Taco Seasoning", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Vanilla Extract", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Almond Extract", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Saffron", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Za'atar", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Five Spice Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sesame Seeds", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Poppy Seeds", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Celery Seed", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sumac", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "MSG", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Nutritional Yeast", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Onion Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Garlic Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Celery Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Lemon Pepper", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(
            name: "Everything Bagel Seasoning", measurement: .standardVolume(default: .tablespoon)
        ),

        // Oils, Vinegars, Condiments & Sauces
        Ingredient(name: "Olive Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(
            name: "Extra Virgin Olive Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Vegetable Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Canola Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Sesame Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Coconut Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Avocado Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Peanut Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Cooking Spray", measurement: .unit()),
        Ingredient(name: "Balsamic Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Red Wine Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(
            name: "White Wine Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(
            name: "Apple Cider Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Rice Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "White Vinegar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Soy Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Tamari", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(
            name: "Worcestershire Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Hot Sauce", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sriracha", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Ketchup", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Mustard", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Dijon Mustard", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Yellow Mustard", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Mayonnaise", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Barbecue Sauce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Ranch Dressing", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Italian Dressing", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Caesar Dressing", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Salsa", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pesto", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Tomato Paste", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Tomato Sauce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Marinara Sauce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Alfredo Sauce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Hoisin Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Oyster Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Fish Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Teriyaki Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Curry Paste", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(
            name: "Chili Garlic Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Tahini", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Peanut Butter", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Almond Butter", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Jam", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Jelly", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Honey", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Maple Syrup", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Molasses", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Agave Nectar", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Corn Syrup", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Chicken Broth", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Beef Broth", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Vegetable Broth", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Bone Broth", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Chicken Stock", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Beef Stock", measurement: .standardVolume(default: .cup)),

        // Baking
        Ingredient(name: "Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "All-Purpose Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Bread Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Whole Wheat Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cake Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Almond Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cornstarch", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Baking Soda", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Baking Powder", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Active Dry Yeast", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Granulated Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Brown Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Powdered Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Coconut Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Chocolate Chips", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Dark Chocolate", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Milk Chocolate", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "White Chocolate", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Cocoa Powder", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Graham Cracker", measurement: .unit()),
        Ingredient(name: "Graham Cracker Crumbs", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pie Crust", measurement: .unit()),
        Ingredient(name: "Puff Pastry", measurement: .unit()),
        Ingredient(name: "Phyllo Dough", measurement: .unit()),
        Ingredient(name: "Marshmallow", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Mini Marshmallow", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sprinkles", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Food Coloring", measurement: .unit()),
        Ingredient(name: "Gelatin", measurement: .unit()),
        Ingredient(name: "Cream of Tartar", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Shortening", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Lard", measurement: .standardVolume(default: .cup)),
        Ingredient(
            name: "Sweetened Condensed Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Instant Pudding Mix", measurement: .unit()),
        Ingredient(name: "Cake Mix", measurement: .unit()),

        // Nuts, Seeds & Legumes
        Ingredient(name: "Almonds", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sliced Almonds", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Walnuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pecans", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cashews", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pistachios", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Peanuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Hazelnuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Macadamia Nuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pine Nuts", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sunflower Seeds", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pumpkin Seeds", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Chia Seeds", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Flax Seeds", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Black Beans", measurement: .unit()),
        Ingredient(name: "Kidney Beans", measurement: .unit()),
        Ingredient(name: "Pinto Beans", measurement: .unit()),
        Ingredient(name: "Chickpeas", measurement: .unit()),
        Ingredient(name: "Cannellini Beans", measurement: .unit()),
        Ingredient(name: "Navy Beans", measurement: .unit()),
        Ingredient(name: "Lima Beans", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Lentils", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Red Lentils", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Green Lentils", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Split Peas", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Black-Eyed Peas", measurement: .unit()),
        Ingredient(name: "Refried Beans", measurement: .unit()),
        Ingredient(name: "Baked Beans", measurement: .unit()),

        // Canned & Jarred Goods
        Ingredient(name: "Canned Tomatoes", measurement: .unit()),
        Ingredient(name: "Diced Tomatoes", measurement: .unit()),
        Ingredient(name: "Crushed Tomatoes", measurement: .unit()),
        Ingredient(name: "Canned Corn", measurement: .unit()),
        Ingredient(name: "Canned Pineapple", measurement: .unit()),
        Ingredient(name: "Chipotle Peppers in Adobo", measurement: .unit()),
        Ingredient(name: "Roasted Red Peppers", measurement: .standardVolume(default: .cup)),

        // Beverages & Cooking Liquids
        Ingredient(name: "White Wine", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Red Wine", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cooking Sherry", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Beer", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Rum", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Bourbon", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Brandy", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Coffee", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Espresso", measurement: .unit()),
        Ingredient(name: "Orange Juice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Lemon Juice", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Lime Juice", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Club Soda", measurement: .standardVolume(default: .cup)),

        // Asian & International Specialty
        Ingredient(name: "Miso Paste", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Mirin", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Sake", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Gochujang", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Kimchi", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Nori", measurement: .unit()),
        Ingredient(name: "Wasabi", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Rice Paper", measurement: .unit()),
        Ingredient(name: "Egg Roll Wrappers", measurement: .unit()),
        Ingredient(name: "Lemongrass", measurement: .unit()),
        Ingredient(name: "Galangal", measurement: .unit()),
        Ingredient(name: "Thai Basil", measurement: .unit()),
        Ingredient(name: "Curry Leaves", measurement: .unit()),
        Ingredient(name: "Dashi", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Furikake", measurement: .standardVolume(default: .tablespoon)),

        // Snacks
        Ingredient(name: "Tortilla Chips", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pita Chips", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Popcorn", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Crackers", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cereal", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Granola", measurement: .standardVolume(default: .cup)),
    ]
}
