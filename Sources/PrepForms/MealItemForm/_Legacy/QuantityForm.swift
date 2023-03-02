//import SwiftUI
//import PrepDataTypes
//import SwiftHaptics
//import SwiftUISugar
//import PrepViews
//import Combine
//import FoodLabel
//import SwiftUIPager
//
//import PrepCoreDataStack
//import PrepMocks
//
//extension MealItemForm {
//    public struct QuantityForm: View {
//        
//        @EnvironmentObject var viewModel: MealItemViewModel
//
//        @Namespace var namespace
//        @Environment(\.colorScheme) var colorScheme
//        @Environment(\.dismiss) var dismiss
//        @Binding var isPresented: Bool
//        
//        @FocusState var isFocused: Bool
//        @State var animatedIsFocused: Bool = false
//        @State var showingUnitPicker = false
//        
//        @State var showingEquivalentQuantitiesInGrid = false
//        @State var equivalentQuantities: [FoodQuantity] = []
//        
//        @StateObject var page: Page = .first()
//        var items = Array(0..<2)
//
//        public init(isPresented: Binding<Bool>) {
//            _isPresented = isPresented
//        }
//    }
//}
//
//public extension MealItemForm.QuantityForm {
//
//    var body: some View {
//        ZStack {
//            content
//            VStack {
//                Spacer()
//                bottomButtons
//            }
//            .edgesIgnoringSafeArea(.bottom)
//            .transition(.move(edge: .bottom))
//        }
//        .scrollDismissesKeyboard(.interactively)
//        .navigationTitle("Quantity")
//        .sheet(isPresented: $showingUnitPicker) { unitPicker }
//        .toolbar { trailingCloseButton }
//        .onAppear(perform: appeared)
//        .onChange(of: isFocused, perform: isFocusedChanged)
//    }
//    
//    func isFocusedChanged(to newValue: Bool) {
//        withAnimation {
//            animatedIsFocused = newValue
//        }
//    }
//    
//    func appeared() {
//        isFocused = true
//    }
//    
//    var metersSection: some View {
//        MealItemMeters(
//            foodItem: $viewModel.mealItem,
//            meal: $viewModel.dayMeal,
//            day: viewModel.day, //TODO: Get
//            userUnits: DataManager.shared.user?.units ?? .standard,
////            bodyProfile: viewModel.day?.bodyProfile //TODO: We need to load the Day's bodyProfile here once supported
//            bodyProfile: DataManager.shared.user?.bodyProfile,
//            didTapGoalSetButton: { forMeal in
//                
//            }
//        )
//    }
//    
////    var goalsPager: some View {
////        Pager(
////            page: page,
////            data: items,
////            id: \.self,
////            content: { index in
////                if index == 0 {
////                    mealGoalsSection
////                } else {
////                    dailyGoalsSection
////                }
////            }
////        )
////        .pagingPriority(.simultaneous)
////        .frame(height: 150)
//////        .vertical()
//////        .alignment(.start)
//////        .horizontal(.endToStart)
//////        .loopPages(true, repeating: 3)
//////        .frame(width: 250)
////    }
//    
//    var legendView: some View {
//        LegendView(
//            prepped: [.energy, .fat, .protein, .carb],
//            increments: [.energy, .fat, .protein, .carb],
//            showCompletion: false,
//            showExcess: false
//        )
//        .fixedSize(horizontal: false, vertical: true)
//        .foregroundColor(Color(.secondaryLabel))
//        .font(.footnote)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, 40)
//    }
//    
//    var content: some View {
//        FormStyledScrollView {
//            textFieldSection
////            equivalentSection
//            metersSection
////            goalsPager
////            legendView
////            mealGoalsSection
////            dailyGoalsSection
////            foodLabelSection
////            legendSection
////            mealIncrementSection
////            goalIncrementSection
////            nutrientsSummarySection
//        }
//        .safeAreaInset(edge: .bottom) {
//            Spacer()
//                .frame(height: 80)
//        }
//    }
//    
//    var trailingCloseButton: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button {
//                Haptics.feedback(style: .soft)
//                isPresented = false
//            } label: {
//                closeButtonLabel
//            }
//        }
//    }
//}
//
//extension MealItemForm.QuantityForm {
//    var foodLabelSection: some View {
//        FormStyledSection {
//            foodLabel
//        }
//    }
//
//    var foodLabel: FoodLabel {
//        let energyBinding = Binding<FoodLabelValue>(
//            get: { .init(amount: 234, unit: .kcal)  },
//            set: { _ in }
//        )
//
//        let carbBinding = Binding<Double>(
//            get: { 56 },
//            set: { _ in }
//        )
//
//        let fatBinding = Binding<Double>(
//            get: { 38  },
//            set: { _ in }
//        )
//
//        let proteinBinding = Binding<Double>(
//            get: { 25 },
//            set: { _ in }
//        )
//        
//        let microsBinding = Binding<[NutrientType : FoodLabelValue]>(
//            get: {
//                [
//                    .saturatedFat : .init(amount: 22, unit: .g),
//                    .sugars : .init(amount: 28, unit: .g),
//                    .calcium : .init(amount: 230, unit: .mg),
//                    .sodium : .init(amount: 1640, unit: .mg),
//                    .transFat : .init(amount: 2, unit: .g),
//                    .dietaryFiber : .init(amount: 6, unit: .g)
//                ]
//            },
//            set: { _ in }
//        )
//        
//        let amountBinding = Binding<String>(
//            get: { "1 cup, chopped" },
//            set: { _ in }
//        )
//
//        return FoodLabel(
//            energyValue: energyBinding,
//            carb: carbBinding,
//            fat: fatBinding,
//            protein: proteinBinding,
//            nutrients: microsBinding,
//            amountPerString: amountBinding
//        )
//    }
//}
//
//extension MealItemForm.QuantityForm {
//    var mealGoalsSection: some View {
//        var header: some View {
//            HStack {
//                Text("Meal Goals")
//                Spacer()
//                Button {
//                    
//                } label: {
//                    HStack {
//                        Text("🏋🏽‍♂️ Pre-Workout")
//                            .textCase(.none)
//                        Image(systemName: "chevron.up.chevron.down")
//                            .imageScale(.small)
//                    }
//                    .foregroundColor(.accentColor)
//                }
//            }
//        }
//        
//        var footer: some View {
//            Text("These goals have been automatically generated by dividing your remaining daily goals by how many meals your have left to plan.")
//        }
//        
//        return FormStyledSection(header: header) {
//            EmptyView()
////            exampleMeters
//        }
//    }
//}
//
//extension MealItemForm.QuantityForm {
//    var dailyGoalsSection: some View {
//        var header: some View {
//            HStack {
//                Text("Daily Goals")
//                Spacer()
//                Button {
//                    
//                } label: {
//                    HStack {
//                        Text("🫃🏽 Weight Loss")
//                            .textCase(.none)
//                        Image(systemName: "chevron.up.chevron.down")
//                            .imageScale(.small)
//                    }
//                    .foregroundColor(.accentColor)
//                }
//            }
//        }
//        
//        var footer: some View {
//            LegendView(
//                prepped: [.energy, .fat, .protein, .carb],
//                increments: [.energy, .fat, .protein, .carb],
//                showCompletion: false,
//                showExcess: false
//            )
//        }
//        
//        return FormStyledSection(header: header) {
//            EmptyView()
////            exampleMeters
//        }
//    }
//}
//
//extension MealItemForm.QuantityForm {
//    var legendSection: some View {
//        FormStyledSection(header: Text("Legend")) {
//            Text("Legend goes here")
//        }
//    }
//}
//
////TODO: Remove this
//struct LegendView: View {
//    
//    let prepped: [NutrientMeterComponent]
//    let increments: [NutrientMeterComponent]
//    let showCompletion: Bool
//    let showExcess: Bool
//    
//    init(
//        prepped: [NutrientMeterComponent] = [],
//        increments: [NutrientMeterComponent] = [],
//        showCompletion: Bool = false,
//        showExcess: Bool = false
//    ) {
//        self.prepped = prepped
//        self.increments = increments
//        self.showCompletion = showCompletion
//        self.showExcess = showExcess
//    }
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack(alignment: .center) {
//                incrementsGrid
////                    .padding(.top, Self.spacing)
//                Text("This is how much of an increase adding this food will result in.")
//            }
//            HStack(alignment: .center) {
//                preppedGrid
////                    .padding(.top, Self.spacing)
//                Text("This is what you have already planned for the day.")
//            }
//        }
//    }
//    
//    static let spacing: CGFloat = 2
//    static let colorSize: CGFloat = 10
//    let cornerRadius: CGFloat = 2
//    
//    static let gridItem = GridItem(.fixed(colorSize), spacing: spacing)
//    static let gridLayout = [gridItem, gridItem]
//    
//    var preppedGrid: some View {
//        LazyVGrid(columns: Self.gridLayout, spacing: Self.spacing) {
//            ForEach(prepped, id: \.self) {
//                colorBox($0.preppedColor)
//            }
//            if showCompletion {
//                colorBox(NutrientMeter.ViewModel.Colors.Complete.placeholder)
//            }
//            if showExcess {
//                colorBox(NutrientMeter.ViewModel.Colors.Excess.placeholder)
//            }
//        }
//        .fixedSize()
//    }
//
//    var incrementsGrid: some View {
//        LazyVGrid(columns: Self.gridLayout, spacing: Self.spacing) {
//            ForEach(increments, id: \.self) {
//                colorBox($0.eatenColor)
//            }
//            if showCompletion {
//                colorBox(NutrientMeter.ViewModel.Colors.Complete.fill)
//            }
//            if showExcess {
//                colorBox(NutrientMeter.ViewModel.Colors.Excess.fill)
//            }
//        }
//        .fixedSize()
//    }
//
//    func colorBox(_ color: Color) -> some View {
//        color
//            .frame(width: Self.colorSize, height: Self.colorSize)
//            .cornerRadius(cornerRadius)
//    }
//}
//
////var exampleMeters: some View {
////    VStack {
////        Grid(alignment: .trailing, verticalSpacing: 2) {
////            GridRow {
////                Text("Energy")
////                    .foregroundColor(NutrientMeterComponent.energy.textColor)
////                    .font(.footnote)
//////                    .font(.title3)
////                NutrientMeter(viewModel: .init(
////                    component: .energy, goal: 400, burned: 0, planned: 170, increment: 180))
////                .frame(height: 15)
////            }
////            GridRow {
////                Text("Carb")
////                    .foregroundColor(NutrientMeterComponent.carb.textColor)
////                    .font(.footnote)
//////                    .fontWeight(.bold)
//////                    .font(.title3)
////                NutrientMeter(viewModel: .init(
////                    component: .carb, goal: 400, burned: 0, planned: 170, increment: 20))
////                .frame(height: 15)
////            }
////            GridRow {
////                Text("Fat")
////                    .foregroundColor(NutrientMeterComponent.fat.textColor)
////                    .font(.footnote)
//////                    .fontWeight(.bold)
//////                    .font(.title3)
////                NutrientMeter(viewModel: .init(
////                    component: .fat, goal: 300, burned: 0, planned: 70, increment: 60))
////                .frame(height: 15)
////            }
////            GridRow {
////                Text("Protein")
////                    .foregroundColor(NutrientMeterComponent.protein.textColor)
////                    .font(.footnote)
//////                    .fontWeight(.bold)
//////                    .font(.title3)
////                NutrientMeter(viewModel: .init(
////                    component: .protein, goal: 600, burned: 0, planned: 170, increment: 70))
////                .frame(height: 15)
////            }
////        }
////    }
////}
////
////struct MiniMeters: View {
////    let width: CGFloat = 60
////    let height: CGFloat = 7
////    let spacing: CGFloat = 2
////    var body: some View {
////        VStack(spacing: spacing) {
////            NutrientMeter(viewModel: .init(
////                component: .energy, goal: 400, burned: 0, planned: 170, increment: 180))
////            .frame(height: height)
////            NutrientMeter(viewModel: .init(
////                component: .carb, goal: 400, burned: 0, planned: 170, increment: 20))
////            .frame(height: height)
////            NutrientMeter(viewModel: .init(
////                component: .fat, goal: 300, burned: 0, planned: 70, increment: 60))
////            .frame(height: height)
////            NutrientMeter(viewModel: .init(
////                component: .protein, goal: 600, burned: 0, planned: 170, increment: 70))
////            .frame(height: height)
////        }
////        .frame(width: width)
////    }
////}
//
////struct LegendViewPreview: View {
////    var body: some View {
////        NavigationView {
////            FormStyledScrollView {
////                FormStyledSection(header: Text("Daily Goals"), footer: footer) {
////                    Text(
////                }
////                FormStyledSection {
////                    HStack {
////                        Text("Here we go")
////                        Spacer()
////                        MiniMeters()
////                        MiniMeters()
////                    }
////                }
////            }
////        }
////    }
////
////    var footer: some View {
////        LegendView(
////            prepped: [.energy, .fat, .protein, .carb],
////            increments: [.energy, .fat, .protein, .carb],
////            showCompletion: true,
////            showExcess: true
////        )
////    }
////}
////
////struct LegendView_Previews: PreviewProvider {
////    static var previews: some View {
////        LegendViewPreview()
////    }
////}
