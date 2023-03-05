//import SwiftUI
//import PrepDataTypes
//import ActivityIndicatorView
//import FoodLabel
//import SwiftUISugar
//
//struct FoodView: View {
//    
//    @EnvironmentObject var foodSearchModel: FoodSearchModel
//
//    @Environment(\.colorScheme) var colorScheme
//    
//    @State var result: FoodSearchResult? = nil
//    @State var food: PrepFood? = nil
//
//    init(_ food: PrepFood) {
//        _food = State(initialValue: food)
//    }
//    
//    init(_ result: FoodSearchResult) {
//        _result = State(initialValue: result)
//    }
//    
//    var body: some View {
//        Group {
//            if let food {
//                foodContents(for: food)
//            } else {
//                loadingContents
//            }
//        }
//        .onAppear {
//            if let result, let food = foodSearchModel.foods.first(where: { $0.id == result.id }) {
//                self.food = food
//            } else {
//                //TODO: Do the task business here
//            }
//        }
//    }
//    
//    func foodContents(for food: PrepFood) -> some View {
//        FormStyledScrollView {
//            detailSection(for: food)
//            foodLabelSection(for: food)
//            pieSection(for: food)
//        }
//        .navigationTitle("Food")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    func pieSection(for food: PrepFood) -> some View {
//        Pie(slices: [
//            (food.carbEnergy, Macro.carb.fillColor(for: colorScheme)),
//            (food.fatEnergy, Macro.fat.fillColor(for: colorScheme)),
//            (food.proteinEnergy, Macro.protein.fillColor(for: colorScheme)),
//        ])
//        .padding(.horizontal, 80)
//        .shadow(radius: 10, x: 0, y: 3)
//    }
//    
//    func detailSection(for food: PrepFood) -> some View {
//        Section {
//            VStack(alignment: .center) {
//                HStack {
//                    Text(food.emoji)
//                        .padding(10)
//                        .background(
//                            Circle()
//                                .foregroundColor(Color(.secondarySystemFill))
//                        )
//                    Text(food.name)
//                        .multilineTextAlignment(.center)
//                        .font(.title)
//                        .bold()
//                }
//                if let detail = food.detail {
//                    Text(detail)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//            }
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundColor(Color(.quaternarySystemFill))
//            )
//            .padding(.top)
//            .padding(.horizontal)
//        }
//    }
//    
//    func foodLabelSection(for food: PrepFood) -> some View {
//        FormStyledSection {
//            FoodLabel(dataSource: food)
//        }
//    }
//    
//    var loadingContents: some View {
//        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
//            .frame(width: 70, height: 70)
//            .foregroundColor(.secondary)
//            .transition(.scale)
//    }
//}
//
//extension PrepFood: FoodLabelDataSource {
//    public var energyValue: FoodLabelValue {
//        FoodLabelValue(amount: energy, unit: .kcal)
//    }
//    
//    public var carbAmount: Double {
//        carb
//    }
//    
//    public var fatAmount: Double {
//        fat
//    }
//    
//    public var proteinAmount: Double {
//        protein
//    }
//    
//    public var nutrients: [NutrientType : Double] {
//        [:]
//    }
//    
//    public var amountPerString: String {
//        "serving"
//    }
//    
//    public var showFooterText: Bool {
//        false
//    }
//}
//
//extension PrepFood {
//    var carbEnergy: Double { carb * KcalsPerGramOfCarb }
//    var fatEnergy: Double { fat * KcalsPerGramOfFat }
//    var proteinEnergy: Double { protein * KcalsPerGramOfProtein }
//}
//struct FoodViewPreview: View {
//    
//    @StateObject var foodSearchModel = FoodSearchModel()
//    
//    var body: some View {
//        if let prepFood {
//            FoodView(prepFood)
//                .environmentObject(foodSearchModel)
//        } else {
//            Color.red
//        }
//    }
//    
//    var prepFood: PrepFood? {
//        PrepFood(serverFood: serverFood)
//    }
//    
//    var serverFood: ServerFood {
//        ServerFood(
//            id: UUID(),
//            name: "Test",
//            emoji: "🤖",
//            detail: nil,
//            brand: nil,
//            amount: ServerAmountWithUnit(double: 1, unit: 1),
//            serving: nil,
//            nutrients: ServerNutrients(energyInKcal: 100, carb: 30, protein: 5, fat: 20, micronutrients: []),
//            sizes: [],
//            density: nil,
//            linkUrl: nil,
//            prefilledUrl: nil,
//            imageIds: nil,
//            type: 1,
//            verificationStatus: 1,
//            database: 1,
//            databaseFoodId: nil)
//    }
//}
//
//struct FoodView_Previews: PreviewProvider {
//    static var previews: some View {
//        FoodViewPreview()
//    }
//}
//
///// From: https://stackoverflow.com/a/73812898
//struct Pie: View {
//
//    @State var slices: [(Double, Color)]
//
//    var body: some View {
//        Canvas { context, size in
//            let donut = Path { p in
//                p.addEllipse(in: CGRect(origin: .zero, size: size))
//                p.addEllipse(in: CGRect(x: size.width * 0.25, y: size.height * 0.25, width: size.width * 0.5, height: size.height * 0.5))
//            }
//            context.clip(to: donut, style: .init(eoFill: true))
//            
//            let total = slices.reduce(0) { $0 + $1.0 }
//            context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
//            var pieContext = context
//            pieContext.rotate(by: .degrees(-90))
//            let radius = min(size.width, size.height) * 0.48
//            var startAngle = Angle.zero
//            for (value, color) in slices {
//                let angle = Angle(degrees: 360 * (value / total))
//                let endAngle = startAngle + angle
//                let path = Path { p in
//                    p.move(to: .zero)
//                    p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
//                    p.closeSubpath()
//                }
////                pieContext.fill(path, with: .color(color))
//                pieContext.fill(
//                    path,
//                    with: .color(color)
////                    with: .radialGradient(Gradient(colors: [color, color]), center: .zero, startRadius: 0, endRadius: radius)
//                )
//
//                startAngle = endAngle
//            }
//        }
//        .aspectRatio(1, contentMode: .fit)
//        
//    }
//}
//
//struct Pie_Previews: PreviewProvider {
//    static var previews: some View {
//        Pie(slices: [
//            (2, Macro.carb.fillColor(for: .dark)),
//            (3, Macro.fat.fillColor(for: .dark)),
//            (4, Macro.protein.fillColor(for: .dark)),
//        ])
//    }
//}
