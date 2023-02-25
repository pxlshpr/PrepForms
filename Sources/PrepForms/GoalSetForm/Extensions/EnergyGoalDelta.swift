import PrepDataTypes

extension EnergyGoalDelta {
    var deltaPickerOption: EnergyDeltaOption {
        switch self {
        case .surplus:
            return .above
        case .deficit:
            return .below
        }
    }
}

