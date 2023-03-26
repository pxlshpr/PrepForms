import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct RestingEnergyComponents: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BiometricsModel
    @State var presentedSheet: Sheet? = nil

    init(_ model: BiometricsModel) {
        self.model = model
    }
    
    var body: some View {
        quickForm
    }
    
    var quickForm: some View {
        NavigationView {
            FormStyledScrollView {
                infoSection
                ageSection
                sexSection
                weightSection
                if model.restingEnergyEquation.requiresHeight {
                    heightSection
                }
            }
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { leadingContent }
            .toolbar { trailingContent }
            .sheet(item: $presentedSheet) { sheet(for: $0) }
        }
    }
    
    var ageSection: some View {
        AgeSection {
            present(.ageSource)
        }
    }
    
    var sexSection: some View {
        BiologicalSexSection(includeFooter: true) {
            present(.sexSource)
        }
    }
    
    var weightSection: some View {
        WeightSection {
            present(.weightSource)
        }
    }
    
    var heightSection: some View {
        HeightSection {
            present(.heightSource)
        }
    }
    
    var infoSection: some View {
        FormStyledSection {
            Text("These are used to calculate your resting energy using the *\(model.restingEnergyEquation.menuDescription)* equation.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
        }
    }
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            syncButton
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            if isValid {
                doneButton
//            } else {
//                dismissButton
//            }
        }
    }
    
    var isValid: Bool {
        model.calculatedRestingEnergy != nil
    }

    @ViewBuilder
    var doneButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            Text("Done")
        }
    }
    
    var dismissButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
        }
    }
    
    @ViewBuilder
    var syncButton: some View {
        if model.shouldShowSyncAllForMeasurementsForm {
            Button {
                model.tappedSyncAllOnMeasurementsForm()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
}

extension RestingEnergyComponents {
    
    enum Sheet: Hashable, Identifiable {
        case weightSource
        case heightSource
        case ageSource
        case sexSource

        var id: Self { self }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .weightSource:
            model.measurementSourcePickerSheet(for: .weight)
        case .heightSource:
            model.measurementSourcePickerSheet(for: .height)
        case .ageSource:
            model.measurementSourcePickerSheet(for: .age)
        case .sexSource:
            model.measurementSourcePickerSheet(for: .sex)
        }
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = sheet
        }
        
        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }
        
        if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
}
