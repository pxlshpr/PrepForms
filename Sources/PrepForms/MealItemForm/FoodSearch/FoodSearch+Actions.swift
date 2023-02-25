import SwiftUI
import PrepDataTypes
import SwiftHaptics

extension FoodSearch {

    func didSubmit() {
        withAnimation {
            shouldShowSearchPrompt = false
        }
        Task {
            await searchManager.performNetworkSearch()
        }
    }

    func isComparingChanged(to newValue: Bool) {
        searchIsFocused = false
    }
    
    func tappedCompare() {
        Haptics.feedback(style: .medium)
        if searchIsFocused {
            searchIsFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isComparing.toggle()
                }
            }
        } else {
            withAnimation {
                isComparing.toggle()
            }
        }
    }
    
    func tappedClose() {
        if let didTapClose {
            didTapClose()
        } else {
            Haptics.feedback(style: .soft)
            dismiss()
        }
    }
}
