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
        // Proteins
        Ingredient(name: "Chicken Breast", measurement: .unit(unitToMass: 500)),
        Ingredient(name: "Chicken Thigh", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Ground Beef", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Ground Turkey", measurement: .standardMass(default: .pound)),
        Ingredient(name: "Pork Chop", measurement: .unit()),
        Ingredient(name: "Bacon", measurement: .unit()),
        Ingredient(name: "Salmon", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Shrimp", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Tofu", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Egg", measurement: .unit()),

        // Grains & Starches
        Ingredient(name: "Rice", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Quinoa", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Pasta", measurement: .standardMass(default: .ounce)),
        Ingredient(name: "Bread", measurement: .unit()),
        Ingredient(name: "Tortilla", measurement: .unit()),
        Ingredient(name: "Potato", measurement: .unit()),
        Ingredient(name: "Sweet Potato", measurement: .unit()),
        Ingredient(name: "Oats", measurement: .standardVolume(default: .cup)),

        // Vegetables
        Ingredient(name: "Broccoli", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Carrot", measurement: .unit()),
        Ingredient(name: "Onion", measurement: .unit()),
        Ingredient(name: "Garlic", measurement: .unit()),
        Ingredient(name: "Bell Pepper", measurement: .unit()),
        Ingredient(name: "Spinach", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Lettuce", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Tomato", measurement: .unit()),
        Ingredient(name: "Cucumber", measurement: .unit()),
        Ingredient(name: "Zucchini", measurement: .unit()),
        Ingredient(name: "Mushroom", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Celery", measurement: .unit()),

        // Fruits
        Ingredient(name: "Apple", measurement: .unit()),
        Ingredient(name: "Banana", measurement: .unit()),
        Ingredient(name: "Lemon", measurement: .unit()),
        Ingredient(name: "Avocado", measurement: .unit()),

        // Dairy
        Ingredient(name: "Milk", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Butter", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Cheddar Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Mozzarella Cheese", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Parmesan Cheese", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Greek Yogurt", measurement: .standardVolume(default: .cup)),

        // Pantry
        Ingredient(name: "Olive Oil", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Salt", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Black Pepper", measurement: .standardVolume(default: .teaspoon)),
        Ingredient(name: "Soy Sauce", measurement: .standardVolume(default: .tablespoon)),
        Ingredient(name: "Flour", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Sugar", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Chicken Broth", measurement: .standardVolume(default: .cup)),
        Ingredient(name: "Canned Tomatoes", measurement: .unit()),
        Ingredient(name: "Black Beans", measurement: .unit()),
    ]
}
