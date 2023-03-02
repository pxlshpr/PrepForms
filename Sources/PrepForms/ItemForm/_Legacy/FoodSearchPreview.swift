//import SwiftUI
//import PrepDataTypes
//import SwiftSugar
//
//public struct FoodSearchPreview: View {
//    enum Route: Hashable {
//        case food(Food)
//    }
//
//    @State var path: [Route] = []
//    
//    @State var foodToShowMacrosFor: Food? = nil
//    
//    @State var searchIsFocused: Bool = false
//    
//    public init() { }
//
//    public var body: some View {
//        NavigationStack(path: $path) {
//            FoodSearch(
//                dataProvider: MockDataProvider(),
//                focusOnAppear: true,
//                searchIsFocused: $searchIsFocused,
//                didTapFood: {
//                    self.path = [.food($0)]
//                },
//                didTapMacrosIndicatorForFood: {
//                    foodToShowMacrosFor = $0
//                }
//            )
//            .sheet(item: $foodToShowMacrosFor, content: { food in
//                Text("Macros for: \(food.name)")
//            })
//            .navigationDestination(for: Route.self, destination: { route in
//                switch route {
//                case .food(let food):
//                    Text("MealItemForm for " + food.name)
//                }
//            })
//        }
//    }
//    
//}
//
//class MockDataProvider: SearchDataProvider {
//    var recentFoods: [Food] {
//        mockFoodsArray
//    }
//    
//    func getFoods(scope: SearchScope, searchText: String, page: Int = 1) async throws -> (foods: [Food], haveMoreResults: Bool) {
//        try await sleepTask(Double.random(in: 2...5))
//        return (mockFoodsArray, false)
//    }
//    
//    var mockFoodsArray: [Food] {
//        [
//            Food(mockName: "Cheese", emoji: "🧀"),
//            Food(mockName: "KFC Leg", emoji: "🍗"),
//            Food(mockName: "Carrot", emoji: "🥕"),
//            Food(mockName: "Beans", emoji: "🫘"),
//            Food(mockName: "Brinjal", emoji: "🍆"),
//        ]
//    }
//}
