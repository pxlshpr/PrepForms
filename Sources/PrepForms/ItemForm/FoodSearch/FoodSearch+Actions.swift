import SwiftUI
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

extension FoodSearch {

    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.interactiveSpring()) {
                hasAppeared = true
            }
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//            initialFocusCompleted = true
//        }
    }
    
    func hideHeroAddButton() {
        withAnimation {
            if showingAddHeroButton {
//                showingAddHeroButton = false
            }
        }
    }
    
    func tappedFood(_ food: Food) {
        if searchIsFocused {
//            didTapFood(food)
            searchIsFocused = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            actionHandler(.tappedFood(food))
//                searchIsFocused = false
//            }
        } else {
            actionHandler(.tappedFood(food))
//            didTapFood(food)
        }
    }
    
    func didAddFood(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let food = userInfo[Notification.Keys.food] as? Food,
              let sourceId = userInfo[Notification.Keys.sourceId] as? UUID,
              sourceId == self.id
        else { return }
        
        print("🧿 Received didAddFood")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            actionHandler(.tappedFood(food))
        }
    }
    
    func didUpdateUser(_ notification: Notification) {
        withAnimation {
            showingEmojis = UserManager.showingLogEmojis
        }
    }
    
    func searchIsFocusedChanged(_ newValue: Bool) {
        if initialSearchIsFocusedChangeIgnored {
            hideHeroAddButton()
        } else {
            initialSearchIsFocusedChangeIgnored = true
        }
    }

    func searchTextChanged(to searchText: String) {
        hideHeroAddButton()
        withAnimation {
            shouldShowRecents = searchText.isEmpty
            shouldShowSearchPrompt = searchModel.hasNotSubmittedSearchYet && searchText.count >= 3
        }
        Task {
            await searchManager.performBackendSearch()
        }
    }

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
        actionHandler(.dismiss)
//        if let didTapClose {
//            didTapClose()
//        } else {
//            Haptics.feedback(style: .soft)
//            dismiss()
//        }
    }
}
