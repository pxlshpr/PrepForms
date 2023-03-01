import SwiftUI
import PrepDataTypes
import FoodLabelScanner
import SwiftHaptics
import PrepViews
import SwiftUISugar

public struct DensityForm: View {
    
    @EnvironmentObject var fields: FoodForm.Fields
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var viewModel: DensityFormViewModel
    
    @State var showingWeightForm = false
    @State var showingVolumeForm = false

    public init(
        initialField: Field? = nil,
        handleNewDensity: @escaping (FoodDensity?) -> ()
    ) {
        _viewModel = StateObject(wrappedValue: .init(
            initialField: initialField,
            handleNewDensity: handleNewDensity
        ))
    }

    public var body: some View {
        NavigationStack {
            QuickForm(
                title: viewModel.title,
                info: saveInfoBinding,
                saveAction: saveActionBinding,
                deleteAction: deleteActionBinding
            ) {
                fieldSection
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingWeightForm) { weightForm }
            .sheet(isPresented: $showingVolumeForm) { volumeForm }
        }
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.hidden)
    }
    
    var weightForm: some View {
        AmountForm(densityFormViewModel: viewModel, forWeight: true)
    }
    
    var volumeForm: some View {
        AmountForm(densityFormViewModel: viewModel, forWeight: false)
    }
    
}

extension DensityForm {
    
    var saveActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                .init(
                    confirmationButtonTitle: viewModel.saveButtonTitle,
                    isDisabled: viewModel.shouldDisableDone,
                    handler: {
                        viewModel.save()
                    }
                )
            },
            set: { _ in }
        )
    }

    var deleteActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                guard viewModel.isEditing else { return nil }
                return .init(
                    shouldConfirm: true,
                    confirmationMessage: nil,
                    isDisabled: false,
                    buttonImage: "trash.fill",
                    handler: {
                        withAnimation {
//                            fields.removeDensity()
                        }
                    }
                )
            },
            set: { _ in }
        )
    }
    
    var saveInfoBinding: Binding<FormSaveInfo?> {
        Binding<FormSaveInfo?>(
            get: {
                nil
            },
            set: { _ in }
        )
    }

}
