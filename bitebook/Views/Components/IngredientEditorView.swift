import SwiftData
import SwiftUI

private enum MeasurementKind: String, CaseIterable, Identifiable {
    case unit = "Counted"
    case standardMass = "Mass"
    case standardVolume = "Volume"

    var id: String { rawValue }
}

struct IngredientEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Ingredient.name)
    private var allIngredients: [Ingredient]

    var ingredient: Ingredient? = nil
    var onSave: ((Ingredient) -> Void)? = nil

    @State private var name: String
    @State private var kind: MeasurementKind
    @State private var massUnit: MassUnit
    @State private var volumeUnit: VolumeUnit
    @State private var unitToMassText: String
    @State private var unitToVolumeText: String

    init(ingredient: Ingredient? = nil, initialName: String = "", onSave: ((Ingredient) -> Void)? = nil) {
        self.ingredient = ingredient
        self.onSave = onSave
        _name = State(initialValue: ingredient?.name ?? initialName)

        switch ingredient?.defaultUnitOfMeasurement {
        case .standardMass(let unit):
            _kind = State(initialValue: .standardMass)
            _massUnit = State(initialValue: unit)
            _volumeUnit = State(initialValue: .cup)
        case .standardVolume(let unit):
            _kind = State(initialValue: .standardVolume)
            _massUnit = State(initialValue: .gram)
            _volumeUnit = State(initialValue: unit)
        case .unit, .none:
            _kind = State(initialValue: .unit)
            _massUnit = State(initialValue: .gram)
            _volumeUnit = State(initialValue: .cup)
        }

        _unitToMassText = State(initialValue: ingredient?.unitToMass.map { $0.formatted() } ?? "")
        _unitToVolumeText = State(
            initialValue: ingredient?.unitToVolume.map { $0.formatted() } ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("New Ingredient", text: $name)
                .textFieldStyle(.plain)
                .font(.title2)
                .bold()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Measurement")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Picker("", selection: $kind) {
                    ForEach(MeasurementKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(isKindLocked)

                if isKindLocked {
                    Text(
                        "Locked — used in \(usedInRecipes.count) recipe\(usedInRecipes.count == 1 ? "" : "s")."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                switch kind {
                case .standardMass:
                    Picker("Default Unit", selection: $massUnit) {
                        ForEach(MassUnit.allCases, id: \.self) { unit in
                            Text(unit.label(for: 2)).tag(unit)
                        }
                    }
                case .standardVolume:
                    Picker("Default Unit", selection: $volumeUnit) {
                        ForEach(VolumeUnit.allCases, id: \.self) { unit in
                            Text(unit.label(for: 2)).tag(unit)
                        }
                    }
                case .unit:
                    HStack {
                        Text("Weight per unit (g)")
                        Spacer()
                        TextField("Optional", text: $unitToMassText)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isUnitToMassInvalid ? .red : .clear, lineWidth: 1.5)
                            )
                    }

                    HStack {
                        Text("Volume per unit (mL)")
                        Spacer()
                        TextField("Optional", text: $unitToVolumeText)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isUnitToVolumeInvalid ? .red : .clear, lineWidth: 1.5)
                            )
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveIngredient()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420, height: 380, alignment: .top)
    }

    private var usedInRecipes: [Recipe] {
        guard let ingredient else { return [] }
        return IngredientLibraryService(modelContext: modelContext).recipes(using: ingredient)
    }

    private var isKindLocked: Bool {
        !usedInRecipes.isEmpty
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameTaken: Bool {
        allIngredients.contains {
            $0.id != ingredient?.id
                && $0.name.compare(trimmedName, options: .caseInsensitive) == .orderedSame
        }
    }

    private var isUnitToMassInvalid: Bool {
        guard !unitToMassText.isEmpty else { return false }
        guard let value = Double(unitToMassText) else { return true }
        return value <= 0
    }

    private var isUnitToVolumeInvalid: Bool {
        guard !unitToVolumeText.isEmpty else { return false }
        guard let value = Double(unitToVolumeText) else { return true }
        return value <= 0
    }

    private var resolvedUnitToMass: Double? {
        unitToMassText.isEmpty ? nil : Double(unitToMassText)
    }

    private var resolvedUnitToVolume: Double? {
        unitToVolumeText.isEmpty ? nil : Double(unitToVolumeText)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !isNameTaken && !isUnitToMassInvalid && !isUnitToVolumeInvalid
    }

    private func saveIngredient() {
        let measurement: IngredientMeasurement
        switch kind {
        case .unit:
            measurement = .unit(unitToMass: resolvedUnitToMass, unitToVolume: resolvedUnitToVolume)
        case .standardMass:
            measurement = .standardMass(default: massUnit)
        case .standardVolume:
            measurement = .standardVolume(default: volumeUnit)
        }

        let saved = IngredientLibraryService(modelContext: modelContext).save(
            ingredient: ingredient, name: trimmedName, measurement: measurement)
        onSave?(saved)
        dismiss()
    }
}
