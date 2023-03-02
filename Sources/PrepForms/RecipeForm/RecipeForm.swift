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

    @Environment(\.dismiss) var dismiss
    
    @StateObject var fields = FoodForm.Fields()
    @StateObject var ingredients = Ingredients()
    
    @State var showingCancelConfirmation = false

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
                .toolbar { navigationTrailingContent }
        }
    }
    
    var foodSearchForm: some View {
        ItemForm.FoodSearch(
            viewModel: ItemForm.ViewModel(existingIngredientItem: nil),
            isInitialFoodSearch: true,
            forIngredient: true,
            actionHandler: { handleItemAction($0, forEdit: false) }
        )
    }
    
    func handleItemAction(_ action: ItemFormAction, forEdit: Bool) {
        switch action {
        case .save(let mealItem, let dayMeal):
            break
        case .delete:
            break
        case .dismiss:
            showingFoodSearch = false
        }
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
    
    var navigationTrailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Group {
//                debugFillButton
                dismissButton
            }
        }
    }
    
    var dismissButton: some View {
        var dismissConfirmationActions: some View {
            Button("Close without saving", role: .destructive) {
                Haptics.feedback(style: .soft)
                dismiss()
            }
        }
        
        var dismissConfirmationMessage: some View {
            Text("You have unsaved data. Are you sure?")
        }
        
        return Button {
            if fields.isDirty {
                Haptics.warningFeedback()
//                showingCancelConfirmation = true
            } else {
                Haptics.feedback(style: .soft)
                dismiss()
//                dismissWithHaptics()
            }
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
        .confirmationDialog(
            "",
            isPresented: $showingCancelConfirmation,
            actions: { dismissConfirmationActions },
            message: { dismissConfirmationMessage }
        )
    }
}
