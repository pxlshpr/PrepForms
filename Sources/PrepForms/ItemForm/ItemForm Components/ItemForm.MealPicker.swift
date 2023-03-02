import SwiftUI
import Timeline
import PrepDataTypes
import SwiftUISugar
import SwiftHaptics

extension ItemForm {
    public struct MealPicker: View {
        
        @EnvironmentObject var viewModel: ViewModel
        
        @Environment(\.dismiss) var dismiss
      
        let didTapMeal: (DayMeal) -> ()
        let didTapDismiss: () -> ()

        public init(
            didTapDismiss: @escaping () -> (),
            didTapMeal: @escaping ((DayMeal) -> ())
        ) {
            self.didTapDismiss = didTapDismiss
            self.didTapMeal = didTapMeal
        }
    }
}

public extension ItemForm.MealPicker {
    
    var body: some View {
        Timeline(
            items: viewModel.timelineItems,
            newItem: nil, //mealItem,
            shouldStylizeTappableItems: true,
            didTapItem: didTapItem,
            didTapOnNewItem: didTapOnNewItem
        )
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pick a Meal")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { trailingCloseButton }
    }
    
    func didTapItem(_ item: TimelineItem) {
        Haptics.feedback(style: .rigid)
        if let dayMeals = viewModel.dayMeals,
           let meal = dayMeals.first(where: { $0.id.uuidString == item.id })
        {
            didTapMeal(meal)
        }
        dismiss()
    }

    var trailingCloseButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                didTapDismiss()
            } label: {
                closeButtonLabel
            }
        }
    }

    func didTapOnNewItem() {
        
    }
}
