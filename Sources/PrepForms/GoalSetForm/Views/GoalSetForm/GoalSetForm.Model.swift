import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension GoalSetForm {
    public class Model: ObservableObject {
        
        let id: UUID
        @Published var name: String
        @Published var emoji: String
        @Published var goalModels: [GoalModel] = []
        @Published var type: GoalSetType = .day
        
        @Published var singleGoalModelToPushTo: GoalModel? = nil
        @Published var implicitGoals: [GoalModel] = []
        
        @Published var path: [GoalSetFormRoute] = []
        let existingGoalSet: GoalSet?
        let isDuplicating: Bool
        
        @Published var shouldShowWizard: Bool = true
        @Published var showingWizardOverlay: Bool  = true
        @Published var showingWizard: Bool  = true
        @Published var formDisabled = false

        init(
            type: GoalSetType,
            existingGoalSet existing: GoalSet?,
            isDuplicating: Bool = false
        ) {
            /// Always generate a new `UUID`, even if we're duplicating or editing (as we soft-delete the previous ones)
            self.id = UUID()
            
            self.name = existing?.name ?? ""
            self.emoji = existing?.emoji ?? randomEmoji(forGoalSetType: type)
            self.type = type
            
            self.isDuplicating = isDuplicating
            self.existingGoalSet = isDuplicating ? nil : existing
            
            self.goalModels = existing?.goals.goalModels(goalSet: self, goalSetType: type) ?? []
            self.createImplicitGoals()
        }
    }
}

extension GoalSetForm.Model {
    
    var isEditing: Bool {
        existingGoalSet != nil && !isDuplicating
    }
        
    var goalSet: GoalSet {
        GoalSet(
            id: id,
            type: type,
            name: name,
            emoji: emoji,
            goals: goalModels.map { $0.goal },
            syncStatus: .notSynced,
            updatedAt: Date().timeIntervalSince1970,
            deletedAt: nil
        )
    }
    
    var isValid: Bool {
        
        /// There should be a name, an emoji, and at least one goal
        guard !name.isEmpty, !emoji.isEmpty, !goalModels.isEmpty else { return false }
        
        guard goalModels.allSatisfy({ $0.isValid }) else { return false }
        return true
    }
    
    var shouldShowSaveButton: Bool {
        guard isValid else { return false }
        if let existingGoalSet, !isDuplicating {
            return !existingGoalSet.equals(goalSet)
        }
        return true
    }

    func didAddNutrients(pickedEnergy: Bool, pickedMacros: [Macro], pickedMicros: [NutrientType]) {
        var newGoalModels: [GoalModel] = []
        if pickedEnergy, !goalModels.containsEnergy {
            newGoalModels.append(GoalModel(
                goalSet: self,
                goalSetType: type,
                type: .energy(.fixed(UserManager.energyUnit))
            ))
        }
        for macro in pickedMacros {
            if !goalModels.containsMacro(macro) {
                newGoalModels.append(GoalModel(
                    goalSet: self,
                    goalSetType: type,
                    type: .macro(.fixed, macro)
                ))
            }
        }
        for nutrientType in pickedMicros {
            if !goalModels.containsMicro(nutrientType) {
                newGoalModels.append(GoalModel(
                    goalSet: self,
                    goalSetType: type,
                    type: .micro(.fixed, nutrientType, nutrientType.units.first ?? .g)
                ))
            }
        }
        goalModels.append(contentsOf: newGoalModels)
        if newGoalModels.count == 1, let singleGoalModel = newGoalModels.first {
            singleGoalModelToPushTo = singleGoalModel
//                self.path.append(.goal(singleGoalModel))
        }
    }
    
    //MARK: - Convenience
    
    var containsGoalWithEquivalentValues: Bool {
        goalModels.contains(where: { $0.type.showsEquivalentValues })
    }
    
    func containsMacro(_ macro: Macro) -> Bool {
        goalModels.containsMacro(macro)
    }
    
    func containsMicro(_ micro: NutrientType) -> Bool {
        goalModels.containsMicro(micro)
    }
    
    var containsSyncedGoal: Bool {
        goalModels.contains(where: { $0.isSynced })
    }
    
    var syncedGoalsCount: Int {
        goalModels.filter({ $0.isSynced }).count
    }
    
    var containsImplicitGoal: Bool {
        !implicitGoals.isEmpty
    }
    
    var implicitGoalName: String? {
        implicitGoals.first?.description
    }
    
    var hasTDEE: Bool {
        UserManager.biometrics.hasTDEE
    }
    
    var hasWeight: Bool {
        UserManager.biometrics.hasWeight
    }
    
    var hasLBM: Bool {
        UserManager.biometrics.hasLBM
    }

    var energyGoal: GoalModel? {
        get {
            goalModels.first(where: { $0.type.isEnergy })
        }
        set {
            guard let newValue else {
                //TODO: maybe use this to remove it by setting it to nil?
                return
            }
            self.goalModels.update(with: newValue)
        }
    }
    
    func goalCalcParams(includeEnergyGoal: Bool = true) -> GoalCalcParams {
        GoalCalcParams(
            units: UserManager.units,
            biometrics: UserManager.biometrics,
            energyGoal: includeEnergyGoal ? energyGoal?.goal : nil
        )
    }
    
    var implicitEnergyGoalIndex: Int? {
        implicitGoals.firstIndex(where: { $0.type == implicitEnergyType })
    }

    func implicitMacroGoalIndex(for macro: Macro) -> Int? {
        implicitGoals.firstIndex(where: { $0.type == .macro(.fixed, macro) })
    }

    var implicitEnergyType: GoalType {
        .energy(.fixed(UserManager.energyUnit))
    }
    
    var carbGoal: GoalModel? { goalModels.first { $0.type.macro == .carb } }
    var fatGoal: GoalModel? { goalModels.first { $0.type.macro == .fat } }
    var proteinGoal: GoalModel? { goalModels.first { $0.type.macro == .protein } }
    
    func createImplicitGoals() {
        withAnimation {
            setOrReplaceImplicitGoal(
                self.energyGoal == nil ? self.getImplicitEnergyGoalModel : nil,
                for: implicitEnergyType
            )
            setOrReplaceImplicitGoal(
                self.carbGoal == nil ? self.getImplicitCarbGoalModel : nil,
                for: .macro(.fixed, .carb)
            )
            setOrReplaceImplicitGoal(
                self.fatGoal == nil ? self.getImplicitFatGoalModel : nil,
                for: .macro(.fixed, .fat)
            )
            setOrReplaceImplicitGoal(
                self.proteinGoal == nil ? self.getImplicitProteinGoalModel : nil,
                for: .macro(.fixed, .protein)
            )
        }
    }
    
    func setOrReplaceImplicitGoal(_ goalModel: GoalModel?, for type: GoalType) {
        /// If we got passed nil, remove the implicit goal
        guard let goalModel else {
            implicitGoals.removeAll(where: { $0.type == type })
            return
        }
        
        if let index = implicitGoals.firstIndex(where: { $0.type == type }) {
            /// If it exists, simply update the bounds
            implicitGoals[index].lowerBound = goalModel.lowerBound
            implicitGoals[index].upperBound = goalModel.upperBound
        } else {
            /// Otherwise append it
            implicitGoals.append(goalModel)
        }

    }
    
    var getImplicitEnergyGoalModel: GoalModel? {
        guard let goal = goalSet.implicitEnergyGoal(
            with: goalCalcParams(includeEnergyGoal: false)
        ) else { return nil }
        
        return GoalModel(implicitGoal: goal, in: self)
    }

    var getImplicitCarbGoalModel: GoalModel? {
        guard let goal = goalSet.implicitCarbGoal(with: goalCalcParams()) else { return nil }
        return GoalModel(implicitGoal: goal, in: self)
    }

    var getImplicitFatGoalModel: GoalModel? {
        guard let goal = goalSet.implicitFatGoal(with: goalCalcParams()) else { return nil }
        return GoalModel(implicitGoal: goal, in: self)
    }

    var getImplicitProteinGoalModel: GoalModel? {
        guard let goal = goalSet.implicitProteinGoal(with: goalCalcParams()) else { return nil }
        return GoalModel(implicitGoal: goal, in: self)
    }

    var macroGoals: [GoalModel] {
        get {
            goalModels
                .filter({ $0.type.isMacro })
                .sorted(by: {
                    ($0.type.macro?.sortOrder ?? 0) < ($1.type.macro?.sortOrder ?? 0)
                })
        }
    }
    
    var microGoals: [GoalModel] {
        get {
            goalModels
                .filter({ $0.type.isMicro })
                .sorted(by: {
                    ($0.type.nutrientType?.rawValue ?? 0) < ($1.type.nutrientType?.rawValue ?? 0)
                })
        }
    }
}

extension Macro {
    var sortOrder: Int {
        switch self {
        case .carb:     return 1
        case .fat:      return 2
        case .protein:  return 3
        }
    }
}

let dietEmojis = "⤵️⤴️🍽️⚖️🏝🏋🏽🚴🏽🍩🍪🥛"
let mealProfileEmojis = "🤏🙌🏋🏽🚴🏽🍩🍪⚖️🥛"

func randomEmoji(forGoalSetType type: GoalSetType) -> String {
    
    let array = type == .meal ? mealProfileEmojis : dietEmojis
    guard let character = array.randomElement() else {
        return "⚖️"
    }
    return String(character)
}
