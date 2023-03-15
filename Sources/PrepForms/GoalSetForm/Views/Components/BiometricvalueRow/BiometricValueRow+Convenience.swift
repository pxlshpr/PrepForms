import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

extension BiometricValueRow {

    var isUserEntered: Bool {
        source.isUserEntered || source.isUserEnteredAndComputed
    }
    
    var isHealthSynced: Bool {
        source.isHealthSynced
    }

    var showingValue: Bool {
        !isHealthSynced || syncStatus != .syncing
    }
    
    var valueString: String {
        let string = value?.valueDescription ?? ""
        if string.isEmpty {
            if isUserEntered {
                return "required"
            } else {
                return placeholder ?? "no data"
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
    
}
