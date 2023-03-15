import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

extension BiometricValueRow {

    var primaryRow: some View {
        HStack {
            syncFailedContent
            Spacer()
            content
        }
    }
    
    var content: some View {
        ZStack(alignment: .bottomTrailing) {
            animatedValueContent.opacity(showingValue ? 1 : 0)
            nonAnimatedContent.opacity(showingValue ? 0 : 1)
        }
    }
    
    @ViewBuilder
    var animatedValueContent: some View {
        if type == .sex {
            sexPicker
        } else {
            if source.isUserEnteredAndComputed {
                computedLeanBodyMassTexts
            } else {
                button
            }
        }
    }
    
    @ViewBuilder
    var nonAnimatedContent: some View {
        if isHealthSynced {
            if syncStatus == .syncing {
                ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                    .frame(width: 25, height: 25)
                    .foregroundColor(.secondary)
            } else if value == nil {
                Text("no data")
                    .font(font)
                    .foregroundColor(.secondary)
            } else {
                EmptyView()
            }
        }
    }
    
    var syncFailedForm: some View {
        BiometricSyncFailedForm(type: type, syncStatus: syncStatus)
    }
    
    @ViewBuilder
    var syncFailedContent: some View {
        if syncStatus == .lastSyncFailed || syncStatus == .nextAvailableSynced {
            Button {
                Haptics.feedback(style: .soft)
                showingSyncFailedInfo = true
            } label: {
                HStack {
                    Text(syncStatus == .lastSyncFailed ? "sync failed" : "no data")
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    Image(systemName: "info.circle")
                        .imageScale(.medium)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
//                .foregroundColor(.red)
                .font(.footnote)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
            }
        }
    }
    
    var form: some View {
        
        let type: BiometricType = isFatPercentage ? .fatPercentage : self.type

        func handleNewValue(_ value: BiometricValue?) {
            Haptics.successFeedback()
            withAnimation {
                self.value = value
            }
        }
        
        return BiometricValueForm(
            type: type,
            initialValue: value,
            handleNewValue: handleNewValue
        )
    }

    var texts: some View {
        HStack {
            if !isFatPercentage, let prefix {
                Text(prefix)
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            if let value {
                Color.clear
                    .animatedBiometricsValueModifier(
                        value: value,
                        type: type,
                        textColor: textColor
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
                .background(
                    background
                        .animation(.none, value: value)
                )
        }
        .disabled(!isUserEntered)
    }
}
