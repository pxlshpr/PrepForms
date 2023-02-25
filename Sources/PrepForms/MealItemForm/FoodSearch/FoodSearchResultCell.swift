import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes
import PrepViews

extension FoodCell {
    init(result: FoodSearchResult) {
        self.init(
            emoji: result.emoji,
            name: result.name,
            detail: result.detail,
            brand: result.brand,
            carb: result.carb,
            fat: result.fat,
            protein: result.protein,
            nameFontWeight: .semibold
        )
    }
}

struct FoodSearchResultCellPreview: View {
    
    var body: some View {
        NavigationView {
            List {
                FoodCell(result: .init(
                    id: UUID(),
                    name: "Gold Emblem",
                    emoji: "🍬",
                    detail: "Fruit Flavored Snacks!, Green Apple, Grape, Black Cherry, Orange, Green Apple, Grape, Black Cherry, Orange",
                    brand: "Cvs Pharmacy, Inc.",
                    carb: 45,
                    fat: 2,
                    protein: 1
                ))
                FoodCell(result: .init(
                    id: UUID(),
                    name: "Golden Beer Battered White Meat Chicken Strip Shaped Patties With Mashed Potatoes And Mixed Vegetables - Includes A Chocolate Brownie",
                    emoji: "🍗",
                    detail: "Beer Battered Chicken",
                    brand: "Campbell Soup Company",
                    carb: 25,
                    fat: 6,
                    protein: 45
                ))
                FoodCell(result: .init(
                    id: UUID(),
                    name: "Golden Brown All Natural Pork Sausage Patties",
                    emoji: "🐷",
                    detail: "Mild, Minimum 18 Patties/Bag, 28 Oz.",
                    brand: "Jones Dairy Farm",
                    carb: 4,
                    fat: 36,
                    protein: 22
                ))
                FoodCell(result: .init(
                    id: UUID(),
                    name: "Banana",
                    emoji: "🍌",
                    detail: "Cavendish, peeled",
                    carb: 4,
                    fat: 36,
                    protein: 22
                ))

            }
        }
    }
}

struct FoodSearchResultCell_Previews: PreviewProvider {
    static var previews: some View {
        FoodSearchResultCellPreview()
    }
}
