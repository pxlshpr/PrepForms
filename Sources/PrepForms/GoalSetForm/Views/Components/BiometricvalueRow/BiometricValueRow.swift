import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

struct BiometricValueRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var value: BiometricValue?
    var computedValue: Binding<BiometricValue?>?
    let type: BiometricType
    let source: BiometricSource
    let syncStatus: BiometricSyncStatus
    let prefix: String?
    let placeholder: String?

    @State var presentedSheet: Sheet? = nil
//    @State var showingForm: Bool = false
//    @State var showingSyncFailedInfo: Bool = false
    
    @Binding var showFormOnAppear: Bool
    
    init(
        value: Binding<BiometricValue?>,
        computedValue: Binding<BiometricValue?>? = nil,
        type: BiometricType,
        source: BiometricSource,
        syncStatus: BiometricSyncStatus = .notSynced,
        prefix: String? = nil,
        placeholder: String? = nil,
        showFormOnAppear: Binding<Bool> = .constant(false)
    ) {
        _value = value
        
        self.computedValue = computedValue
        
        self.type = type
        self.source = source
        self.syncStatus = syncStatus
        self.prefix = prefix
        self.placeholder = placeholder
        _showFormOnAppear = showFormOnAppear
    }
    
    enum Sheet: String, Identifiable {
        case form
        case syncFailedInfo
        case sexPickerSheet
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack {
            optionalSecondaryRow
            primaryRow
        }
        .sheet(item: $presentedSheet) { sheet(for: $0) }
        .onAppear(perform: appeared)
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .form:
            form
        case .syncFailedInfo:
            syncFailedForm
        case .sexPickerSheet:
            sexPickerSheet
        }
    }
    
    var sexPickerSheet: some View {
        PickerSheet(
            title: "Biological Sex",
            items: BiometricSex.pickerItems,
            pickedItem: value?.sex?.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedSex = BiometricSex(pickerItem: $0) else { return }
                value = .sex(pickedSex)
            }
        )
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
    
    func appeared() {
        if showFormOnAppear {
            Haptics.feedback(style: .soft)
            if type == .sex {
                present(.sexPickerSheet)
            } else {
                present(.form)
            }
            showFormOnAppear = false
        }
    }
}
