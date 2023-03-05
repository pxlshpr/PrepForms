//import SwiftUI
//import SwiftUISugar
//import PrepDataTypes
//import SwiftHaptics
//
//extension MealItemForm.QuantityForm {
//    
//    @ViewBuilder
//    var quantitiesContent: some View {
//        if showingEquivalentQuantitiesInGrid {
//            quantitiesGrid
//        } else {
//            quantitiesScrollView
//        }
//    }
//    
//    var quantitiesGrid: some View {
//        FlowLayout(
//            mode: .scrollable,
//            items: model.equivalentQuantities,
//            itemSpacing: 4,
//            shouldAnimateHeight: .constant(true)
//        ) { quantity in
//            quantityButton(for: quantity)
//        }
//        .padding(.horizontal, 17)
//    }
//    
//    var quantitiesScrollView: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                ForEach(model.equivalentQuantities, id: \.self) { quantity in
//                    quantityButton(for: quantity)
//                }
//            }
//            .padding(.horizontal, 17)
//        }
//    }
//    
//    func quantityButton(for quantity: FoodQuantity) -> some View {
//        Button {
//            Haptics.feedback(style: .rigid)
//            model.didPickQuantity(quantity)
//        } label: {
//            ZStack {
//                Capsule(style: .continuous)
//                    .foregroundColor(Color(.secondarySystemFill))
//                HStack(spacing: 5) {
//                    Text(quantity.value.cleanAmount)
//                        .foregroundColor(Color(.tertiaryLabel))
//                    Text(quantity.unit.shortDescription)
//                        .foregroundColor(Color(.secondaryLabel))
//                }
//                .frame(height: 25)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 5)
//            }
//            .fixedSize(horizontal: true, vertical: true)
//        }
//        .matchedGeometryEffect(id: quantity.description, in: namespace)
//    }
//}
//
//struct AmountFormPreview: View {
//    @StateObject var model = MealItemViewModel(food: .init(mockName: "Cheese", emoji: "🧀"), meal: nil, dayMeals: [])
//    var body: some View {
//        MealItemForm.QuantityForm(isPresented: .constant(true))
//            .environmentObject(model)
//    }
//}
//
//struct AmountForm_Previews: PreviewProvider {
//    static var previews: some View {
//        AmountFormPreview()
//    }
//}
