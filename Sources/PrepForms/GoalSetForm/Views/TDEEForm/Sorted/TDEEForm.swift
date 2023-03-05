import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import HealthKit

public struct TDEEForm: View {
    
    @Namespace var namespace
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject var model: Model
    
    @FocusState var restingEnergyTextFieldIsFocused: Bool
    @FocusState var activeEnergyTextFieldIsFocused: Bool
    
    let didTapSave: (BodyProfile) -> ()
    
    let didEnterForeground = NotificationCenter.default.publisher(for: .didEnterForeground)
    
    @State var showingSaveButton: Bool = false
    
    public init(
        existingProfile: BodyProfile? = nil,
        userUnits: UserOptions.Units,
        didTapSave: @escaping (BodyProfile) -> ()
    ) {
        let model = Model(
            existingProfile: existingProfile,
            userUnits: userUnits
        )
        if let existingProfile, existingProfile.tdeeInUnit != nil {
            detentHeightPrimary = .collapsed
            detentHeightSecondary = .collapsed
        } else {
            detentHeightPrimary = .empty
            detentHeightSecondary = .empty
        }
        _model = StateObject(wrappedValue: model)
        
        self.didTapSave = didTapSave
    }
    
    @ViewBuilder
    public var body: some View {
        Group {
            if model.hasAppeared {
                navigationView
            } else {
                Color(.systemGroupedBackground)
                    .onAppear(perform: blankViewAppeared)
            }
        }
        .onReceive(didEnterForeground, perform: didEnterForeground)
        .presentationDetents(model.detents, selection: $model.presentationDetent)
        .presentationDragIndicator(.hidden)
    }
    
    var navigationView: some View {
//        NavigationStack(path: $model.path) {
        NavigationView {
            ZStack {
                form
                buttonLayer
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Maintenance Calories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingContent }
            .toolbar { leadingContent }
            .onChange(of: model.restingEnergySource, perform: restingEnergySourceChanged)
            .onChange(of: model.activeEnergySource, perform: activeEnergySourceChanged)
            .onChange(of: canBeSaved, perform: canBeSavedChanged)
//            .navigationDestination(for: TDEEFormRoute.self, destination: navigationDestinationForm)
            .interactiveDismissDisabled(model.isEditing && canBeSaved)
            .task { await initialTask() }
        }
    }
    
    func canBeSavedChanged(to newValue: Bool) {
        withAnimation {
            showingSaveButton = newValue
        }
    }
    
    func navigationDestinationForm(for route: TDEEFormRoute) -> some View {
        cprint("We getting: \(route)")
        return Group {
            switch route {
            case .profileForm:
                ProfileForm()
                    .environmentObject(model)
            case .leanBodyMassForm:
                LeanBodyMassForm()
                    .environmentObject(model)
            }
        }
    }
    
    //MARK: - Unsorted
    
    @State var showingAdaptiveCorrectionInfo = false
    
    
    @State var applyActivityScaleFactor: Bool = true
    
    @State var bmrEquation: RestingEnergyFormula = .mifflinStJeor
    @State var activityLevel: ActivityLevel = .moderatelyActive
    @State var biologicalSex: HKBiologicalSex = .male
    @State var weightUnit: WeightUnit = .kg
    @State var heightUnit: HeightUnit = .cm
    
    @State var manualBMR: Bool = false
    @State var bmrUnit: EnergyUnit = .kcal
    @State var bmrDouble: Double? = nil
    @State var bmrString: String = ""
    
    @State var manualTDEE: Bool = false
    @State var tdeeUnit: EnergyUnit = .kcal
    @State var tdeeDouble: Double? = nil
    @State var tdeeString: String = ""
    
    @State var weightDouble: Double? = nil
    @State var weightString: String = ""
    @State var weightDate: Date? = nil
    
    @State var heightDouble: Double? = nil
    @State var heightString: String = ""
    @State var heightDate: Date? = nil
    
    @State var heightSecondaryDouble: Double? = nil
    @State var heightSecondaryString: String = ""
    
    @State var valuesHaveChanged: Bool = true
    
    @State var healthRestingEnergy: Double? = nil
    @State var healthActiveEnergy: Double? = nil
    
    @State var healthEnergyPeriod: HealthPeriodOption = .previousDay
    @State var healthEnergyPeriodInterval: DateComponents = DateComponents(day: 1)
    
    //    @State var useHealthAppData = false
}
