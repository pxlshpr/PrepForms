import SwiftUI
import SwiftUISugar
import PrepDataTypes

public struct NutrientLeanBodyMassForm: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: TDEEForm.ViewModel
    
    @State var showingSaveButton: Bool = false
    
    let didTapSave: (BodyProfile) -> ()
    let didTapClose: () -> ()

    let existingProfile: BodyProfile?
    
    init(
        existingProfile: BodyProfile?,
        didTapSave: @escaping ((BodyProfile) -> ()),
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
        LeanBodyMassForm()
            .safeAreaInset(edge: .bottom) { safeAreaInset }
            .environmentObject(viewModel)
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
                didTapSave(viewModel.bodyProfile)
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

extension NutrientLeanBodyMassForm {
    var canBeSaved:Bool {
        /// If we have an existing profile—return false if the parameters are exactly the same
        if let existingProfile {
            guard existingProfile != viewModel.bodyProfile else {
                return false
            }
        }
        /// In either case, return true only if there is a valid lean body mass value
        return viewModel.bodyProfile.hasLBM
    }
}

extension BodyProfile {
    var hasLBM: Bool {
        lbm != nil && lbmSource != nil
    }
}
