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
    
    @StateObject var model: DensityFormViewModel
    
    @State var showingWeightForm = false
    @State var showingVolumeForm = false

    public init(
        initialField: Field? = nil,
        handleNewDensity: @escaping (FoodDensity?) -> ()
    ) {
        _model = StateObject(wrappedValue: .init(
            initialField: initialField,
            handleNewDensity: handleNewDensity
        ))
    }

    public var body: some View {
        NavigationStack {
            QuickForm(
                title: model.title,
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
        AmountForm(densityFormViewModel: model, forWeight: true)
    }
    
    var volumeForm: some View {
        AmountForm(densityFormViewModel: model, forWeight: false)
    }
    
}

extension DensityForm {
    
    var saveActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                .init(
                    confirmationButtonTitle: model.saveButtonTitle,
                    isDisabled: model.shouldDisableDone,
                    handler: {
                        model.save()
                    }
                )
            },
            set: { _ in }
        )
    }

    var deleteActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                guard model.isEditing else { return nil }
                return .init(
                    shouldConfirm: true,
                    confirmationMessage: nil,
                    isDisabled: false,
                    buttonImage: "trash.fill",
                    handler: {
                        withAnimation {
                            fields.density = .init(fieldValue: .density(.init()))
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
