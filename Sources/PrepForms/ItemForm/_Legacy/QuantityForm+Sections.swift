//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//
//extension MealItemForm.QuantityForm {
//    var textFieldSection: some View {
//        var header: some View {
//            Text(model.amountHeaderString)
//        }
//        
//        return FormStyledSection(header: header) {
//            HStack {
//                textField
//                unitButton
//            }
//        }
//    }
//    
//    var equivalentSection: some View {
//        var header: some View {
//            HStack {
//                Text("Similar Quantities")
//                Spacer()
//                Button {
//                    Haptics.feedback(style: .soft)
//                    withAnimation {
//                        showingEquivalentQuantitiesInGrid.toggle()
//                    }
//                } label: {
//                    Image(systemName: showingEquivalentQuantitiesInGrid ? "square.grid.3x2.fill" : "square.grid.3x2")
//                }
//            }
//        }
//
//        return Group {
//            if !model.equivalentQuantities.isEmpty {
//                FormStyledSection(header: header, horizontalPadding: 0) {
//                    quantitiesContent
//                }
//            }
//        }
//    }
//}
//
////TODO: Bring these in one by one
//extension MealItemForm.QuantityForm {
//    
//    var nutrientsSummarySection: some View {
//        FormStyledSection(header: Text("Nutrients")) {
//            Text("Let the user see at a glance of how much this amount would equate to in terms of its nutrients. Only show a summary here and let them tap on this cell to pop up a sheet with the Food Label and any further visualisations such as a pie chart etc.")
//                .foregroundColor(.secondary)
//        }
//    }
//
//    var goalIncrementSection: some View {
//        FormStyledSection(header: Text("Daily Consumption")) {
//            Text("Show how much this increases your daily consumption (against a goal if applicable).")
//                .foregroundColor(.secondary)
//        }
//    }
//
//    var mealIncrementSection: some View {
//        FormStyledSection(header: Text("Meal Nutrients")) {
//            Text("Show how much this increases the nutrients of the chosen meal (if its not the only item in it).")
//                .foregroundColor(.secondary)
//        }
//    }
//}
