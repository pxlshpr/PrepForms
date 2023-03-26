import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack

extension HealthPeriod {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = HealthPeriod(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: description,
            detail: nil,
            secondaryDetail: nil
        )
    }
}


extension HealthIntervalType {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = HealthIntervalType(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail,
            systemImage: systemImage
        )
    }
    
    var systemImage: String? {
        switch self {
        case .latest:
            return "calendar.badge.clock"
        case .average:
            return "sum"
        }
    }

    var pickerDetail: String? {
        switch self {
        case .latest:
            return "Use the latest available value."
        case .average:
            return "Use the average daily value of the past x days/weeks/months. "
        }
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .latest:
            return nil
        case .average:
            return "This will be a rolling average that updates every day."
        }
    }
}

extension RestingEnergyEquation {
    static var pickerItems: [PickerItem] {
        allCases
            .sorted(by: { $0.year > $1.year })
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = RestingEnergyEquation(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail
        )
    }
    
    var pickerTitle: String {
        "\(pickerDescription) • \(year)"
    }

    var pickerDetail: String? {
        switch self {
        case .rozaShizgal:
            return "This is the revised Harris-Benedict equation."
        case .schofield:
            return "This is the equation used by the WHO."
        default:
            return nil
        }
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .katchMcardle, .cunningham:
            return "Uses your lean body mass."
        case .henryOxford, .schofield:
            return "Uses your age, weight and biological sex."
        case .mifflinStJeor, .rozaShizgal, .harrisBenedict:
            return "Uses your age, weight, height and biological sex."
        }
    }
}

extension LeanBodyMassEquation {
    static var pickerItems: [PickerItem] {
        allCases
            .sorted(by: { $0.year > $1.year })
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = LeanBodyMassEquation(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: nil,
            secondaryDetail: pickerDetail
        )
    }
    
    var pickerTitle: String {
        "\(pickerDescription)"
    }

    var pickerDetail: String? {
        switch self {
        case .boer:
            return "Best suitable for obese individuals."
        case .james:
            return "The is the most widely used equation."
        case .hume:
            return "This is an old but dependable equation that was confirmed in a 2015 research to be reliable."
        }
    }

    var pickerSecondaryDetail: String? {
        return nil
        switch self {
        case .boer:
            return "Uses your weight, height and biological sex."
        case .james:
            return "Uses your weight, height and biological sex."
        case .hume:
            return "Uses your weight, height and biological sex."
        }
    }
}

extension MeasurementSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = MeasurementSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension LeanBodyMassSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = LeanBodyMassSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .fatPercentage:
            return "Calculate using your fat percentage."
        case .equation:
            return "Calculate using an equation."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension ActiveEnergySource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = ActiveEnergySource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage,
            colorStyle: colorStyle
        )
    }
    
    var colorStyle: PickerItem.ColorStyle? {
        switch self {
        case .health:
            return .gradient(HealthTopColor, HealthBottomColor)
        default:
            return nil
        }
    }

    var pickerDetail: String {
        switch self {
        case .activityLevel:
            return "Calculate by choosing how active you are on a scale."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension RestingEnergySource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = RestingEnergySource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage,
            colorStyle: colorStyle
        )
    }
    
    var colorStyle: PickerItem.ColorStyle? {
        switch self {
        case .health:
            return .gradient(HealthTopColor, HealthBottomColor)
        default:
            return nil
        }
    }
    
    var pickerDetail: String {
        switch self {
        case .equation:
            return "Calculate using an equation."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension MeasurementSexSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = MeasurementSexSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: nil,
            systemImage: systemImage
        )
    }
    
    public var pickerDescription: String {
        switch self {
        case .health:
            return "Sync with Health App"
        case .userEntered:
            return "Choose it"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .health:
            return "heart.fill"
        case .userEntered:
            return "hand.tap"
        }
    }
}

extension ActivityLevel {
    static var pickerItems: [PickerItem] {
        allCases
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = ActivityLevel(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail
        )
    }
    
    var pickerTitle: String {
        description
    }

    var pickerDetail: String? {
        nil
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .notSet:
            return "Using this will assign 0 \(UserManager.energyUnit.shortDescription) as your active energy component."
        case .sedentary:
            return "Little or no exercise, working a desk job."
        case .lightlyActive:
            return "Light exercise 1-2 days / week."
        case .moderatelyActive:
            return "Moderate exercise 3-5 days / week."
        case .active:
            return "Heavy exercise 6-7 days / week."
        case .veryActive:
            return "Very heavy exercise 2 or more times per day, hard labor job or training for a marathon, triathlon, etc."
        }
    }
}

extension BiometricSex {
    static var pickerItems: [PickerItem] {
        [Self.female, Self.male]
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = BiometricSex(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: nil,
            secondaryDetail: nil
        )
    }
    
    var pickerTitle: String {
        description
    }
}

extension BodyMassType {
    var pickerDetail: String {
        switch self {
        case .leanMass:
            return "Lean body mass is your weight minus your body fat"
        case .weight:
            return "Your body weight"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerTitle: String {
        switch self {
        case .weight:
            return "weight"
        case .leanMass:
            return "lean body mass"
        }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: pickerTitle,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension BodyMassUnit {
    var pickerDetail: String {
        switch self {
        case .kg:
            return "Kilograms"
        case .lb:
            return "Pounds"
        case .st:
            return "Stones"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: shortDescription,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension WorkoutDurationUnit {
    var pickerDetail: String {
        switch self {
        case .hour:
            return "e.g. 600mg / hour of exercise"
        case .min:
            return "e.g. 0.5g / min of exercise"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: pickerDescription,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension EnergyGoalDelta {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: shortDescription,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .deficit:
            return "e.g. 500 \(UserManager.energyUnit.shortDescription) deficit from your maintenance energy"
        case .surplus:
            return "e.g. 500 \(UserManager.energyUnit.shortDescription) surplus from your maintenance energy"
        case .deviation:
            return "e.g. within 200 \(UserManager.energyUnit.shortDescription) of your maintenance energy"
        }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else {
            return nil
        }
        self.init(rawValue: int16)
    }
}
