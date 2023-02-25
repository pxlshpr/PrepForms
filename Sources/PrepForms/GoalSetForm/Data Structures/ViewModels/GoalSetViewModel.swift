import SwiftUI
import PrepDataTypes

public class GoalSetViewModel: ObservableObject {
    
    let id: UUID
    @Published var name: String
    @Published var emoji: String
    @Published var goalViewModels: [GoalViewModel] = []
    @Published var type: GoalSetType = .day
    
    /// Used to calculate equivalent values
    let userUnits: UserUnits
    @Published var bodyProfile: BodyProfile?
    
    @Published var nutrientTDEEFormViewModel: TDEEForm.ViewModel
    @Published var path: [GoalSetFormRoute] = []
    let existingGoalSet: GoalSet?
    let isDuplicating: Bool
    
    @Published var singleGoalViewModelToPushTo: GoalViewModel? = nil
    
    init(
        userUnits: UserUnits,
        type: GoalSetType,
        existingGoalSet existing: GoalSet?,
        isDuplicating: Bool = false,
        bodyProfile: BodyProfile? = nil
    ) {
        /// Always generate a new `UUID`, even if we're duplicating or editing (as we soft-delete the previous ones)
//        self.id = existing?.id ?? UUID()
        self.id = UUID()
        
        self.name = existing?.name ?? ""
        self.emoji = existing?.emoji ?? randomEmoji(forGoalSetType: type)
        self.type = type

        self.userUnits = userUnits
        self.bodyProfile = bodyProfile

        self.isDuplicating = isDuplicating
        self.existingGoalSet = isDuplicating ? nil : existing

        self.nutrientTDEEFormViewModel = TDEEForm.ViewModel(existingProfile: bodyProfile, userUnits: userUnits)
        self.goalViewModels = existing?.goals.goalViewModels(goalSet: self, goalSetType: type) ?? []
        self.createImplicitGoals()
    }
    
    var isEditing: Bool {
        existingGoalSet != nil && !isDuplicating
    }
        
    var goalSet: GoalSet {
        GoalSet(
            id: id,
            type: type,
            name: name,
            emoji: emoji,
            goals: goalViewModels.map { $0.goal },
            syncStatus: .notSynced,
            updatedAt: Date().timeIntervalSince1970,
            deletedAt: nil
        )
    }
    
    var isValid: Bool {
        
        /// There should be a name, an emoji, and at least one goal
        guard !name.isEmpty, !emoji.isEmpty, !goalViewModels.isEmpty else { return false }
        
        guard goalViewModels.allSatisfy({ $0.isValid }) else { return false }
        return true
    }
    
    var shouldShowSaveButton: Bool {
        guard isValid else { return false }
        if let existingGoalSet, !isDuplicating {
            return !existingGoalSet.equals(goalSet)
        }
        return true
    }

    func resetNutrientTDEEFormViewModel() {
        setNutrientTDEEFormViewModel(with: bodyProfile)
    }
    
    func setNutrientTDEEFormViewModel(with bodyProfile: BodyProfile?) {
        nutrientTDEEFormViewModel = TDEEForm.ViewModel(existingProfile: bodyProfile, userUnits: userUnits)
    }
    
    func setBodyProfile(_ bodyProfile: BodyProfile) {
        /// in addition to setting the current body Profile, we also update the view model (TDEEForm.ViewModel) we have  in GoalSetViewModel (or at least the relevant fields for weight and lbm)
        self.bodyProfile = bodyProfile
        setNutrientTDEEFormViewModel(with: bodyProfile)
    }
    
    func didAddNutrients(pickedEnergy: Bool, pickedMacros: [Macro], pickedMicros: [NutrientType]) {
        var newGoalViewModels: [GoalViewModel] = []
        if pickedEnergy, !goalViewModels.containsEnergy {
            newGoalViewModels.append(GoalViewModel(
                goalSet: self,
                goalSetType: type,
                type: .energy(.fixed(userUnits.energy))
            ))
        }
        for macro in pickedMacros {
            if !goalViewModels.containsMacro(macro) {
                newGoalViewModels.append(GoalViewModel(
                    goalSet: self,
                    goalSetType: type,
                    type: .macro(.fixed, macro)
                ))
            }
        }
        for nutrientType in pickedMicros {
            if !goalViewModels.containsMicro(nutrientType) {
                newGoalViewModels.append(GoalViewModel(
                    goalSet: self,
                    goalSetType: type,
                    type: .micro(.fixed, nutrientType, nutrientType.units.first ?? .g)
                ))
            }
        }
        goalViewModels.append(contentsOf: newGoalViewModels)
        if newGoalViewModels.count == 1, let singleGoalViewModel = newGoalViewModels.first {
            singleGoalViewModelToPushTo = singleGoalViewModel
//                self.path.append(.goal(singleGoalViewModel))
        }
    }
    
    //MARK: - Convenience
    
    var containsGoalWithEquivalentValues: Bool {
        goalViewModels.contains(where: { $0.type.showsEquivalentValues })
    }
    
    func containsMacro(_ macro: Macro) -> Bool {
        goalViewModels.containsMacro(macro)
    }
    
    func containsMicro(_ micro: NutrientType) -> Bool {
        goalViewModels.containsMicro(micro)
    }
    
    var containsDynamicGoal: Bool {
        goalViewModels.contains(where: { $0.isDynamic })
    }
    
    var dynamicGoalsCount: Int {
        goalViewModels.filter({ $0.isDynamic }).count
    }
    
    var containsImplicitGoal: Bool {
        !implicitGoals.isEmpty
    }
    
    var implicitGoalName: String? {
        implicitGoals.first?.description
    }
    
    var hasTDEE: Bool {
        bodyProfile?.hasTDEE ?? false
    }
    
    var hasWeight: Bool {
        bodyProfile?.hasWeight ?? false
    }
    var hasLBM: Bool {
        bodyProfile?.hasLBM ?? false
    }

    var energyGoal: GoalViewModel? {
        get {
            goalViewModels.first(where: { $0.type.isEnergy })
        }
        set {
            guard let newValue else {
                //TODO: maybe use this to remove it by setting it to nil?
                return
            }
            self.goalViewModels.update(with: newValue)
        }
    }
    
    func goalCalcParams(includeEnergyGoal: Bool = true) -> GoalCalcParams {
        GoalCalcParams(
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            energyGoal: includeEnergyGoal ? energyGoal?.goal : nil
        )
    }
    
    @Published var implicitGoals: [GoalViewModel] = []

    var implicitEnergyGoalIndex: Int? {
        implicitGoals.firstIndex(where: { $0.type == implicitEnergyType })
    }

    func implicitMacroGoalIndex(for macro: Macro) -> Int? {
        implicitGoals.firstIndex(where: { $0.type == .macro(.fixed, macro) })
    }

    var implicitEnergyType: GoalType {
        .energy(.fixed(userUnits.energy))
    }
    
    var carbGoal: GoalViewModel? { goalViewModels.first { $0.type.macro == .carb } }
    var fatGoal: GoalViewModel? { goalViewModels.first { $0.type.macro == .fat } }
    var proteinGoal: GoalViewModel? { goalViewModels.first { $0.type.macro == .protein } }
    
    func createImplicitGoals() {
        withAnimation {
            setOrReplaceImplicitGoal(
                self.energyGoal == nil ? self.getImplicitEnergyGoalViewModel : nil,
                for: implicitEnergyType
            )
            setOrReplaceImplicitGoal(
                self.carbGoal == nil ? self.getImplicitCarbGoalViewModel : nil,
                for: .macro(.fixed, .carb)
            )
            setOrReplaceImplicitGoal(
                self.fatGoal == nil ? self.getImplicitFatGoalViewModel : nil,
                for: .macro(.fixed, .fat)
            )
            setOrReplaceImplicitGoal(
                self.proteinGoal == nil ? self.getImplicitProteinGoalViewModel : nil,
                for: .macro(.fixed, .protein)
            )
        }
    }
    
    func setOrReplaceImplicitGoal(_ goalViewModel: GoalViewModel?, for type: GoalType) {
        /// If we got passed nil, remove the implicit goal
        guard let goalViewModel else {
            implicitGoals.removeAll(where: { $0.type == type })
            return
        }
        
        if let index = implicitGoals.firstIndex(where: { $0.type == type }) {
            /// If it exists, simply update the bounds
            implicitGoals[index].lowerBound = goalViewModel.lowerBound
            implicitGoals[index].upperBound = goalViewModel.upperBound
        } else {
            /// Otherwise append it
            implicitGoals.append(goalViewModel)
        }

    }
    
    var getImplicitEnergyGoalViewModel: GoalViewModel? {
        guard let goal = goalSet.implicitEnergyGoal(
            with: goalCalcParams(includeEnergyGoal: false)
        ) else { return nil }
        
        return GoalViewModel(implicitGoal: goal, in: self)
    }

    var getImplicitCarbGoalViewModel: GoalViewModel? {
        guard let goal = goalSet.implicitCarbGoal(with: goalCalcParams()) else { return nil }
        return GoalViewModel(implicitGoal: goal, in: self)
    }

    var getImplicitFatGoalViewModel: GoalViewModel? {
        guard let goal = goalSet.implicitFatGoal(with: goalCalcParams()) else { return nil }
        return GoalViewModel(implicitGoal: goal, in: self)
    }

    var getImplicitProteinGoalViewModel: GoalViewModel? {
        guard let goal = goalSet.implicitProteinGoal(with: goalCalcParams()) else { return nil }
        return GoalViewModel(implicitGoal: goal, in: self)
    }

    var macroGoals: [GoalViewModel] {
        get {
            goalViewModels
                .filter({ $0.type.isMacro })
                .sorted(by: {
                    ($0.type.macro?.sortOrder ?? 0) < ($1.type.macro?.sortOrder ?? 0)
                })
        }
    }
    
    var microGoals: [GoalViewModel] {
        get {
            goalViewModels
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
