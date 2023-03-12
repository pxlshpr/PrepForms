import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

struct BiometricValueRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var value: BiometricValue?
    let type: BiometricType
    let source: BiometricSource
    let fetchStatus: HealthKitFetchStatus
    let prefix: String?
    let matchedGeometryId: String?
    let matchedGeometryNamespace: Namespace.ID?

    @State var showingForm: Bool = false
    @Binding var showFormOnAppear: Bool
    
    init(
        value: Binding<BiometricValue?>,
        type: BiometricType,
        source: BiometricSource,
        fetchStatus: HealthKitFetchStatus,
        prefix: String? = nil,
        showFormOnAppear: Binding<Bool> = .constant(false),
        matchedGeometryId: String? = nil,
        matchedGeometryNamespace: Namespace.ID? = nil
    ) {
        _value = value
        
        self.type = type
        self.source = source
        self.fetchStatus = fetchStatus
        self.prefix = prefix
        self.matchedGeometryId = matchedGeometryId
        self.matchedGeometryNamespace = matchedGeometryNamespace
        
        if type == .sex {
            _showFormOnAppear = .constant(false)
        } else {
            _showFormOnAppear = showFormOnAppear
        }
    }
    
    enum Style {
        case calculated
        case userEntered
    }
    
    var body: some View {
        HStack {
            Spacer()
            content
        }
        .sheet(isPresented: $showingForm) { form }
        .onAppear(perform: appeared)
    }
    func appeared() {
        if showFormOnAppear {
            Haptics.feedback(style: .soft)
            showingForm = true
            showFormOnAppear = false
        }
    }
    
    var form: some View {
        func handleNewValue(_ value: BiometricValue?) {
            Haptics.successFeedback()
            withAnimation {
                self.value = value
            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            }
        }
        
        return BiometricValueForm(
            type: type,
            initialValue: value,
            handleNewValue: handleNewValue
        )
    }
    
    var isUserEntered: Bool {
        source.isUserEntered
    }
    
    var isHealthSynced: Bool {
        source.isHealthSynced
    }

    var showingValue: Bool {
        !isHealthSynced || fetchStatus == .fetched
    }
    
    @ViewBuilder
    var nonAnimatedContent: some View {
        if isHealthSynced {
            switch fetchStatus {
            case .fetching, .notFetched:
                ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                    .frame(width: 25, height: 25)
                    .foregroundColor(.secondary)
            case .fetched:
                EmptyView()
            case .noData:
                Text("no data")
                    .font(font)
                    .foregroundColor(.secondary)
            case .noDataOrNotAuthorized:
                Text("no data or not authorized")
                    .font(font)
                    .foregroundColor(.secondary)
            }
        }
    }
    @ViewBuilder
    var content: some View {
        ZStack(alignment: .bottomTrailing) {
            animatedValueContent
                .opacity(showingValue ? 1 : 0)
            nonAnimatedContent
                .opacity(showingValue ? 0 : 1)
        }
    }
    
    var valueString: String {
        //TODO: Pass this in?
        let string = value?.valueDescription ?? ""
        if string.isEmpty {
            if isUserEntered {
                return "required"
            } else {
                switch type {
                case .activeEnergy:
                    return "needs resting energy"
                default:
                    return "no data"
                }
            }
        } else {
            return string
        }
    }
    
    var unitString: String? {
        if valueString.isEmpty, isUserEntered {
            return nil
        } else {
            return value?.unitDescription
        }
    }
    
    var font: Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }
    
    var textColor: Color {
        isUserEntered ? .accentColor : .secondary
    }
    
    var texts: some View {
        HStack {
            if let prefix {
                Text(prefix)
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            if let value {
                Color.clear
                    .animatedBiometricsValueModifier(
                        value: value,
                        type: type,
                        textColor: textColor,
                        matchedGeometryId: matchedGeometryId,
                        namespace: matchedGeometryNamespace
                    )
            } else {
                Text(valueString)
                    .font(font)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(textColor)
                    .opacity(0.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    @ViewBuilder
    var animatedValueContent: some View {
        if type == .sex {
            sexPicker
        } else {
            button
        }
    }
    
    var sexPicker: some View {
        let sexBinding = Binding<BiometricSex>(
            get: { value?.sex ?? .female },
            set: { newValue in
                value = .sex(newValue)
            }
        )
        
        var labelString: String {
            if !isUserEntered, fetchStatus == .noData {
                return "no data"
            } else {
                return sexBinding.wrappedValue.description
            }
        }
        
        return Menu {
            Picker(selection: sexBinding, label: EmptyView()) {
                ForEach([BiometricSex.female, BiometricSex.male], id: \.self) {
                    Text($0.description).tag($0)
                }
            }
        } label: {
            HStack {
                Text(labelString)
                    .font(font)
                    .multilineTextAlignment(.trailing)
                if isUserEntered {
                    Image(systemName: "chevron.up.chevron.down")
                        .fontWeight(.semibold)
                        .imageScale(.small)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(background)
        }
        .animation(.none, value: value)
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .light)
        })
        .disabled(!isUserEntered)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                Color.accentColor
                    .opacity(colorScheme == .dark ? 0.1 : 0.15)
            )
            .opacity(isUserEntered ? 1 : 0)
    }

    var button: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingForm = true
        } label: {
            texts
                .padding(.vertical, isUserEntered ? 8 : 0)
                .padding(.horizontal, isUserEntered ? 15 : 0)
                .background(background)
        }
        .disabled(!isUserEntered)
    }
}


struct AnimatableBiometricsValueModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: BiometricValue
    let type: BiometricType
    let textColor: Color
    let matchedGeometryId: String?
    let namespace: Namespace.ID?
    
    var animatableData: Double {
        get { value.double ?? 0 }
        set { value.double = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var valueString: String {
        value.valueDescription
    }
    
    var secondaryValueString: String? {
        value.secondaryValueDescription
    }
    
    var secondaryUnitString: String? {
        value.secondaryUnitDescription
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(valueString)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(textColor)
                .if(matchedGeometryId != nil && namespace != nil) {
                    $0.matchedGeometryEffect(id: matchedGeometryId!, in: namespace!)
                }

            if let unit = value.unitDescription {
                Text(unit)
                    .foregroundColor(textColor)
                    .font(.system(.body, design: .rounded, weight: .regular))
            }
            if let secondaryValueString, let secondaryUnitString {
                Text(secondaryValueString)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(textColor)
                Text(secondaryUnitString)
                    .foregroundColor(textColor)
                    .font(.system(.body, design: .rounded, weight: .regular))
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedBiometricsValueModifier(
        value: BiometricValue,
        type: BiometricType,
        textColor: Color,
        matchedGeometryId: String?,
        namespace: Namespace.ID?
    ) -> some View {
        modifier(AnimatableBiometricsValueModifier(
            value: value,
            type: type,
            textColor: textColor,
            matchedGeometryId: matchedGeometryId,
            namespace: namespace
        ))
    }
}
