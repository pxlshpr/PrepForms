import SwiftUI
import PrepCoreDataStack
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews

public struct RecipeForm: View {
    
    @StateObject var fields = FoodForm.Fields()
    @StateObject var ingredients = Ingredients()
    
    @State var showingDetailsForm = false
    @State var showingEmojiPicker = false
    @State var showingFoodSearch = false

    public init() {
        
    }

    public var body: some View {
        content
            .sheet(isPresented: $showingDetailsForm) { detailsForm }
            .sheet(isPresented: $showingFoodSearch) { foodSearchForm }
    }
    
    var content: some View {
        ZStack {
            navigationView
            saveSheet
                .zIndex(3)
        }
    }
    
    var navigationView: some View {
        var formContent: some View {
            ZStack {
                formLayer
//                saveButtonLayer
//                    .zIndex(3)
//                loadingLayer
//                    .zIndex(4)
            }
        }
        
        return NavigationStack {
            formContent
                .navigationTitle("New Recipe")
        }
    }
    
    var foodSearchForm: some View {
        Color.clear
//        ItemForm.FoodSearch(
//            viewModel: ItemForm.ViewModel(existingMealFoodItem: nil, date: Date()),
//            isInitialFoodSearch: true,
//            actionHandler: { _ in
////                handleMealItemAction($0, forEdit: false)
//            }
//        )
    }
    
    var formLayer: some View {
        FormStyledScrollView(showsIndicators: false, isLazy: false) {
            detailsSection
            servingSection
            ingredientsSection
        }
        .safeAreaInset(edge: .bottom) { Spacer().frame(height: 60) }
    }
    
    var ingredientsSection: some View {
        var header: some View {
            Text("Ingredients")
        }
        
        return FormStyledSection(header: header) {
            IngredientsCell(actionHandler: handleIngredientsAction)
                .environmentObject(ingredients)
        }
    }
    
    func handleIngredientsAction(_ action: IngredientsCell.Action) {
        switch action {
        case .add:
            showingFoodSearch = true
        }
    }
    
    var detailsSection: some View {
        FormStyledSection(header: Text("Details")) {
            FoodDetailsCell(
                didTapEmoji: { showingEmojiPicker = true },
                didTapDetails: { showingDetailsForm = true }
            )
            .environmentObject(fields)
        }
    }
    
    var servingSection: some View {
        FormStyledSection(header: Text("Servings and Sizes")) {
            NavigationLink {
                NutrientsPerForm(fields: fields, forIngredients: true)
            } label: {
                if fields.hasAmount {
                    ServingsAndSizesCell(forIngredients: true)
                        .environmentObject(fields)
                } else {
                    Text("Required")
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    var detailsForm: some View {
        DetailsQuickForm(brandLabel: "Source")
            .environmentObject(fields)
    }

    var saveSheet: some View {
        EmptyView()
    }
}
