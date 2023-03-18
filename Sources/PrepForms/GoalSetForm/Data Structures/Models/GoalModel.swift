import SwiftUI
import PrepDataTypes
import Combine
import PrepCoreDataStack

public class GoalModel: ObservableObject, Identifiable {
    
    public let id = UUID()
    var goalSetModel: GoalSetForm.Model
    let goalSetType: GoalSetType
    let isAutoGenerated: Bool
    
    @Published var type: GoalType
    @Published var lowerBound: Double?
    @Published var upperBound: Double?
    
    var anyCancellable: AnyCancellable? = nil
        
    public init(
        goalSet: GoalSetForm.Model,
        goalSetType: GoalSetType = .day,
        type: GoalType,
        lowerBound: Double? = nil,
        upperBound: Double? = nil,
        isAutoGenerated: Bool = false
    ) {
        self.goalSetModel = goalSet
        self.goalSetType = goalSetType
        self.type = type
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.isAutoGenerated = isAutoGenerated
        
//        anyCancellable = goalSet.objectWillChange.sink { [weak self] (_) in
//            withAnimation {
//                self?.objectWillChange.send()
//            }
//        }
    }
    
    convenience init(implicitGoal goal: Goal, in goalSet: GoalSetForm.Model) {
        self.init(
            goalSet: goalSet,
            goalSetType: goalSet.type,
            type: goal.type,
            lowerBound: goal.lowerBound,
            upperBound: goal.upperBound,
            isAutoGenerated: true
        )
    }
    
    var isValid: Bool {
        if let nutrientGoalType, nutrientGoalType.isQuantityPerWorkoutDuration {
            return hasOneBound
        }
        return hasOneEquivalentBound
    }
    
    //MARK: - Energy
    var energyGoalType: EnergyGoalType? {
        get {
            switch type {
            case .energy(let type):
                return type
            default:
                return nil
            }
        }
        set {
            guard let newValue else { return }
            switch type {
            case .energy:
                self.type = .energy(newValue)
            default:
                break
            }
        }
    }
    
    var haveEquivalentValues: Bool {
        switch type {
        case .energy(let energyGoalType):
            switch energyGoalType {
            case .fixed:
                return false
            default:
                break
            }
        case .macro(let type, _):
            switch type {
            case .fixed:
                return false
            default:
                break
            }
        case .micro(let type, _, _):
            switch type {
            case .fixed:
                return false
            default:
                break
            }
        }
        return equivalentLowerBound != nil || equivalentUpperBound != nil
    }
    
    var energyGoalDelta: EnergyGoalDelta? {
        switch type {
        case .energy(let type):
            return type.delta
        default:
            return nil
        }
    }
    
    //MARK: - Macro
    var macro: Macro? {
        switch type {
        case .macro(_, let macro):
            return macro
        default:
            return nil
        }
    }
    
    var nutrientGoalType: NutrientGoalType? {
        get {
            switch type {
            case .macro(let type, _):
                return type
            case .micro(let type, _, _):
                return type
            default:
                return nil
            }
        }
        set {
            guard let newValue else { return }
            switch type {
            case .macro(_, let macro):
                self.type = .macro(newValue, macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                self.type = .micro(newValue, nutrientType, nutrientUnit)
            default:
                break
            }
        }
    }

    var bodyMassUnit: BodyMassUnit? {
        guard let nutrientGoalType else { return nil }
        switch nutrientGoalType {
        case .quantityPerBodyMass(_, let bodyMassUnit):
            return bodyMassUnit
        default:
            return nil
        }
    }
    
    var bodyMassType: NutrientGoalBodyMassType? {
        guard let nutrientGoalType else { return nil }
        switch nutrientGoalType {
        case .quantityPerBodyMass(let bodyMassType, _):
            return bodyMassType
        default:
            return nil
        }
    }
    
    //MARK: - Micro
    
    var microNutrientType: NutrientType? {
        switch type {
        case .micro(_, let nutrientType, _):
            return nutrientType
        default:
            return nil
        }
    }
    
    var microNutrientUnit: NutrientUnit? {
        get {
            switch type {
            case .micro(_, _, let nutrientUnit):
                return nutrientUnit
            default:
                return nil
            }
        }
        set {
            guard let newValue else { return }
            switch type {
            case .micro(let microGoalType, let nutrientType, _):
                self.type = .micro(microGoalType, nutrientType, newValue)
            default:
                break
            }
        }
    }

    var nutrientUnit: NutrientUnit? {
        switch type {
        case .macro:
            return .g
        case .micro(_, let nutrientType, _):
            return nutrientType.units.first
        default:
            return nil
        }
    }
    
    //MARK: - Common
    var isEmpty: Bool {
        !hasOneBound
    }
    
    var workoutDurationUnit: WorkoutDurationUnit? {
        guard let nutrientGoalType else { return nil }
        switch nutrientGoalType {
        case .quantityPerWorkoutDuration(let workoutDurationUnit):
            return workoutDurationUnit
        default:
            return nil
        }
    }
    
    var isQuantityPerWorkoutDuration: Bool {
        workoutDurationUnit != nil
    }
    
    var energyUnit: EnergyUnit? {
        switch energyGoalType {
        case .fixed(let energyUnit):
            return energyUnit
        case .fromMaintenance(let energyUnit, _):
            return energyUnit
        default:
            return nil
        }
    }
    
    var haveBothBounds: Bool {
        lowerBound != nil && upperBound != nil
    }

    var hasOneBound: Bool {
        lowerBound != nil || upperBound != nil
    }

    var hasOneEquivalentBound: Bool {
        equivalentLowerBound != nil || equivalentUpperBound != nil
    }
    
    var isSynced: Bool {
        guard !isAutoGenerated else {
            /// If this is autogenerated—then its synced if any of the other macros or energy are also auto-generated
            return goalSetModel.containsSyncedMacroOrEnergyGoal
        }
        
        switch type {
        case .energy:
            return energyGoalTypeIsSynced
        case .macro(let type, _):
            return nutrientGoalTypeIsSynced(type)
        case .micro(let type, _, _):
            return nutrientGoalTypeIsSynced(type)
        }
    }
    
    func nutrientGoalTypeIsSynced(_ nutrientGoalType: NutrientGoalType) -> Bool {
        switch nutrientGoalType {
        case .quantityPerBodyMass:
            return bodyMassIsSyncedWithHealth
        case .percentageOfEnergy:
            return energyGoalIsSyncedWithHealth
        default:
            return false
        }
    }
    
    var bodyMassIsSyncedWithHealth: Bool {
        guard let nutrientGoalType, nutrientGoalType.isQuantityPerBodyMass,
              let bodyMassType
        else { return false }
        
        switch bodyMassType {
        case .weight:
            return UserManager.biometrics.syncsWeight
        case .leanMass:
            return UserManager.biometrics.syncsLeanBodyMass
        }
    }
    
    var energyGoalIsSyncedWithHealth: Bool {
        goalSetModel.energyGoal?.energyGoalTypeIsSynced ?? false
    }
    
    var energyGoalTypeIsSynced: Bool {
        guard let energyGoalType else { return false }
        switch energyGoalType {
        case .fromMaintenance, .percentFromMaintenance:
            return UserManager.biometrics.syncsMaintenanceEnergy
        default:
            return false
        }
    }

    var placeholderTextColor: Color? {
        guard let nutrientGoalType else { return nil }
        switch nutrientGoalType {
        case .quantityPerWorkoutDuration:
            return Color(.secondaryLabel)
        default:
            return nil
        }
    }
    
    var placeholderText: String? {
        /// First check that we have at least one value—otherwise returning the default placeholder
        guard hasOneBound else {
            return "Set Goal"
        }
        
        /// Now check for special cases (dependent goals, etc)
        switch type {
        case .energy(let type):
            switch type {
            case .fixed:
                break
            case .fromMaintenance, .percentFromMaintenance:
                guard goalSetModel.hasTDEE else {
                    return "Set Maintenance Energy"
                }
            }
        case .macro, .micro:
            return nutrientPlaceholderText
        }
        return nil
    }
    
    var canBeCalculated: Bool {
        missingRequirement == nil
        && nutrientGoalType?.isQuantityPerWorkoutDuration == false
    }
    
    var missingRequirement: GoalRequirement? {
        isMissingRequirement ? requirement : nil
    }
    
    var isMissingRequirement: Bool {
        guard let requirement else { return false }
        switch requirement {
        case .maintenanceEnergy:
            return !UserManager.biometrics.hasTDEE
            
        case .leanMass:
            return !UserManager.biometrics.hasLBM
            
        case .weight:
            return !UserManager.biometrics.hasWeight

        case .energyGoal:
            return goalSetModel.energyGoal?.hasOneEquivalentBound == false
            
        case .workoutDuration:
            return true
        }
    }
    
    var requirement: GoalRequirement? {
        type.requirement
    }
    
    var nutrientPlaceholderText: String? {
        guard let nutrientGoalType else { return nil }
        switch nutrientGoalType {
        case .fixed:
            break
        case .quantityPerBodyMass(let bodyMass, _):
            switch bodyMass {
            case .weight:
                guard goalSetModel.hasWeight else {
                    return "Set Weight"
                }
            case .leanMass:
                guard goalSetModel.hasLBM else {
                    return "Set Lean Body Mass"
                }
            }
        case .percentageOfEnergy, .quantityPerEnergy:
            guard let energyGoal = goalSetModel.energyGoal,
                  energyGoal.hasOneEquivalentBound
            else {
                return "Set Energy Goal"
            }
            return nil
        case .quantityPerWorkoutDuration:
            return "Calculated when used"
        }
        return nil
    }
    
}

extension GoalModel {
    func validateBoundsNotEqual() {
        guard let lowerBound, let upperBound else { return }
        if lowerBound == upperBound {
            withAnimation {
                self.lowerBound = nil
            }
        }
    }
    func validateLowerBoundLowerThanUpper() {
        guard let lowerBound, let upperBound else { return }
        if lowerBound > upperBound {
            withAnimation {
                self.lowerBound = upperBound
                self.upperBound = lowerBound
            }
        }
    }

    func validateNoBoundResultingInLessThan500(unit: EnergyUnit) {
        guard let tdee = UserManager.biometrics.tdee(in: unit)?.rounded()
        else { return }
        
        if let lowerBound, tdee - lowerBound < 500 {
            withAnimation {
                self.lowerBound = tdee - 500
            }
        }

        if let upperBound, tdee - upperBound < 500 {
            withAnimation {
                self.upperBound = tdee - 500
            }
        }
    }
    
    func validateNoPercentageBoundResultingInLessThan500() {
        guard let tdee = UserManager.biometrics.tdee?.rounded()
        else { return }
        
        if let lowerBound, tdee - ((lowerBound/100) * tdee) < 500 {
            withAnimation {
                self.lowerBound = (tdee-500)/tdee * 100
            }
        }

        if let upperBound, tdee - ((upperBound/100) * tdee) < 500 {
            withAnimation {
                self.upperBound = (tdee-500)/tdee * 100
            }
        }
    }
    func validateNoPercentageBoundGreaterThan100() {
        if let lowerBound, lowerBound > 100 {
            withAnimation {
                self.lowerBound = 100
            }
        }
        if let upperBound, upperBound > 100 {
            withAnimation {
                self.upperBound = 100
            }
        }
    }

    func validateEnergy() {
        guard let energyGoalType else { return }
        switch energyGoalType {
        case .fixed:
            break
        case .fromMaintenance(let energyUnit, let delta):
            switch delta {
            case .surplus:
                break
            case .deficit:
                validateNoBoundResultingInLessThan500(unit: energyUnit)
            case .deviation:
                //TODO: Deviation
                validateNoBoundResultingInLessThan500(unit: energyUnit)
            }
        case .percentFromMaintenance(let delta):
            switch delta {
            case .surplus:
                break
            case .deficit:
                validateNoPercentageBoundResultingInLessThan500()
            case .deviation:
                //TODO: Deviation
                validateNoPercentageBoundResultingInLessThan500()
            }
        }
        validateLowerBoundLowerThanUpper()
        validateBoundsNotEqual()
    }

    //TODO: Do this
    func validateNutrient() {
        guard let nutrientGoalType else { return }
        switch nutrientGoalType {
        case .fixed:
            break
        case .quantityPerBodyMass:
            break
        case .quantityPerWorkoutDuration:
            break
        case .percentageOfEnergy:
            break
        case .quantityPerEnergy:
            break
        }
        validateLowerBoundLowerThanUpper()
        validateBoundsNotEqual()
    }

    var debugDescription: String {
        "\(description): \(lowerBound?.cleanAmount ?? "nil") \(upperBound?.cleanAmount ?? "nil")"
    }
    
    var description: String {
        switch type {
        case .energy:
            return "Energy"
        case .macro:
            return macro?.description ?? "Macro"
        case .micro:
            return microNutrientType?.description ?? "Micro"
        }
    }
}

//MARK: Unit String


extension GoalModel {
    var unitStrings: (String, String?) {
        switch type {
        case .energy(let type):
            return type.unitStrings
        case .macro(let type, _):
            return type.unitStrings(nutrientUnit: .g)
        case .micro(let type, _, let nutrientUnit):
            return type.unitStrings(nutrientUnit: nutrientUnit)
        }
    }
}

//MARK: Equivalent Values

import PrepDataTypes

extension GoalModel {
    
    var equivalentUnitString: String? {
        goal.equivalentUnitString(UserManager.units)
    }

    var goal: Goal {
        Goal(
            type: type,
            lowerBound: lowerBound,
            upperBound: upperBound
        )
    }
    
    var goalCalcParams: GoalCalcParams {
        goalSetModel.goalCalcParams(includeEnergyGoal: !type.isEnergy)
    }
    
    var equivalentLowerBound: Double? {
        goal.calculateLowerBound(with: goalCalcParams)
    }
    
    var equivalentUpperBound: Double? {
        goal.calculateUpperBound(with: goalCalcParams)
    }
}

extension GoalModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.identifyingHashValue)
    }
}

extension GoalModel: Equatable {
    public static func ==(lhs: GoalModel, rhs: GoalModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
