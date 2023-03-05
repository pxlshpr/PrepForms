import SwiftUI
import PrepDataTypes
import FoodLabelScanner
import SwiftHaptics
import PrepViews
import SwiftUISugar

public struct SizeForm: View {
    
    @EnvironmentObject var fields: FoodForm.Fields
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    
    @State var showingUnitPicker = false
    @State var hasFocusedOnAppear: Bool = false
    @State var hasCompletedFocusedOnAppearAnimation: Bool = false

    @StateObject var model: SizeFormModel
    
    @State var showingQuantityForm = false
    @State var showingAmountForm = false
    @State var showingNameForm = false
    @State var showingVolumePrefixUnitPicker = false

    public init(
        initialField: Field? = nil,
        handleNewSize: @escaping (FormSize) -> ()
    ) {
        _model = StateObject(wrappedValue: .init(
            initialField: initialField,
            handleNewSize: handleNewSize
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
                Spacer().frame(height: 8)
                toggleSection
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: isFocused, perform: isFocusedChanged)
            .onChange(of: model.showingVolumePrefixToggle,
                      perform: model.changedShowingVolumePrefixToggle
            )
            .sheet(isPresented: $showingAmountForm) { amountForm }
            .sheet(isPresented: $showingQuantityForm) { quantityForm }
            .sheet(isPresented: $showingNameForm) { nameForm }
            .sheet(isPresented: $showingVolumePrefixUnitPicker) { unitPicker }
        }
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.hidden)
    }
    
    var unitPicker: some View {
        UnitPickerGridTiered(
            pickedUnit: .volume(model.volumePrefixUnit),
            includeServing: false,
            includeWeights: false,
            includeVolumes: true,
            sizes: [],
            allowAddSize: false,
            didPickUnit: { newUnit in
                withAnimation {
                    Haptics.feedback(style: .rigid)
                    model.volumePrefixUnit = newUnit.volumeUnit ?? .cup
                }
            }
        )
    }
    
    func isFocusedChanged(_ newValue: Bool) {
        if !isFocused {
            dismiss()
        }
    }
    
    var amountForm: some View {
        AmountForm(sizeFormModel: model)
    }
    
    var quantityForm: some View {
        QuantityForm(sizeFormModel: model)
    }
    
    var nameForm: some View {
        NameForm(sizeFormModel: model)
    }
}

extension SizeForm {
    
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
                        guard let initialSize = model.initialField?.size else { return }
                        withAnimation {
                            fields.removeSize(initialSize)
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
