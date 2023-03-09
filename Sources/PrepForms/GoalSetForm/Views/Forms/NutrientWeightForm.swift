import SwiftUI
import SwiftUISugar
import PrepDataTypes

public struct NutrientWeightForm: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: BiometricsModel
    
    @State var showingSaveButton: Bool = false

    let didTapSave: (Biometrics) -> ()
    let didTapClose: () -> ()

    let existingProfile: Biometrics?
    
    init(
        existingProfile: Biometrics?,
        didTapSave: @escaping ((Biometrics) -> ()),
        didTapClose: @escaping (() -> ())
    ) {
        self.existingProfile = existingProfile
        self.didTapSave = didTapSave
        self.didTapClose = didTapClose
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                form
                buttonLayer
            }
            .toolbar { leadingContent }
        }
        .interactiveDismissDisabled(canBeSaved)
        .onChange(of: canBeSaved, perform: canBeSavedChanged)
    }
    
    func canBeSavedChanged(to newValue: Bool) {
        withAnimation {
            showingSaveButton = newValue
        }
    }

    var form: some View {
        FormStyledScrollView {
            WeightSection(includeHeader: false)
                .environmentObject(model)
                .navigationTitle("Weight")
        }
        .safeAreaInset(edge: .bottom) { safeAreaInset }
    }

    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                didTapClose()
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
    
    @ViewBuilder
    var safeAreaInset: some View {
        if showingSaveButton {
            Spacer()
                .frame(height: 100)
        }
    }

    @ViewBuilder
    var buttonLayer: some View {
        if showingSaveButton {
            VStack {
                Spacer()
                saveButton
            }
            .transition(.move(edge: .bottom))
        }
    }

    var saveButton: some View {
        var saveButton: some View {
            FormPrimaryButton(title: "Save") {
                didTapSave(model.biometrics)
                dismiss()
            }
        }
        
        return VStack(spacing: 0) {
            Divider()
            VStack {
                saveButton
                    .padding(.vertical)
            }
        }
        .background(.thinMaterial)
    }
}

extension NutrientWeightForm {
    var canBeSaved:Bool {
        /// If we have an existing profile—return false if the parameters are exactly the same
        if let existingProfile {
            guard existingProfile != model.biometrics else {
                return false
            }
        }
        /// In either case, return true only if there is a valid lean body mass value
        return model.biometrics.hasWeight
    }
}

extension Biometrics {
    var hasWeight: Bool {
        //TODO: Biometrics
//        true
        weight?.amount != nil && weight?.source != nil
    }
    
    var weightUpdatesWithHealth: Bool {
        //TODO: Biometrics
//        true
        weight?.source == .healthApp
    }
    
    var lbmUpdatesWithHealth: Bool {
        //TODO: Biometrics
//        true
        switch leanBodyMass?.source {
        case .healthApp:
            return true
        case .fatPercentage, .formula:
            return weightUpdatesWithHealth
        default:
            return false
        }
    }
}
