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

    @State var showingForm: Bool = false
    @State var showingSyncFailedInfo: Bool = false
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
        
        if type == .sex {
            _showFormOnAppear = .constant(false)
        } else {
            _showFormOnAppear = showFormOnAppear
        }
    }
    
    var body: some View {
        VStack {
            optionalSecondaryRow
            primaryRow
        }
        .sheet(isPresented: $showingForm) { form }
        .sheet(isPresented: $showingSyncFailedInfo) { syncFailedForm }
        .onAppear(perform: appeared)
    }
    
    func appeared() {
        if showFormOnAppear {
            Haptics.feedback(style: .soft)
            showingForm = true
            showFormOnAppear = false
        }
    }
}
