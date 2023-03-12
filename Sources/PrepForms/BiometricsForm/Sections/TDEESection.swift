import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

struct TDEESection: View {
    
    let largeTitle: Bool
    let includeHeader: Bool
    
    @Namespace var namespace

    @EnvironmentObject var model: BiometricsModel
    @Environment(\.colorScheme) var colorScheme

    init(includeHeader: Bool = false, largeTitle: Bool = false) {
        self.includeHeader = includeHeader
        self.largeTitle = largeTitle
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
//        .onChange(of: model.weightSource, perform: weightSourceChanged)
    }

    @ViewBuilder
    var header: some View {
        if includeHeader {
            biometricHeaderView(UserManager.tdeeDescription, largeTitle: largeTitle)
        }
    }

    var content: some View {
        emptyContent
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSync)
            BiometricButton("Setup", systemImage: "hand.tap", action: tappedSetup)
        }
    }
    
    func tappedSync() {
        Haptics.feedback(style: .soft)
//        model.changeWeightSource(to: .health)
    }
    
    func tappedSetup() {
        Haptics.feedback(style: .soft)
//        model.changeWeightSource(to: .userEntered)
    }
}
