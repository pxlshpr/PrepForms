import SwiftUI
import PrepCoreDataStack
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews

public struct ParentFoodForm: View {

    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: ViewModel
    @StateObject var fields = FoodForm.Fields()
    
    @State var showingCancelConfirmation = false

    @State var showingDetailsForm = false
    @State var showingEmojiPicker = false
    @State var showingFoodSearch = false
    
    public init(forRecipe: Bool) {
        let viewModel = ViewModel(forRecipe: forRecipe)
        _viewModel = StateObject(wrappedValue: viewModel)
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
                .navigationTitle(viewModel.title)
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
        case .saveIngredientItem(let item):
            Haptics.successFeedback()
            if forEdit {
                //TODO: Update ingredient
            } else {
                withAnimation {
                    viewModel.add(item)
                }
            }
            viewModel.recalculateBadgeWdiths()
            
        case .delete:
            break
            
        case .dismiss:
            showingFoodSearch = false
            
        default:
            break
        }
    }
    
    var formLayer: some View {
        FormStyledScrollView(showsIndicators: false, isLazy: false) {
            detailsSection
            if viewModel.forRecipe {
                servingSection
            }
            ingredientsSection
        }
        .safeAreaInset(edge: .bottom) { Spacer().frame(height: 60) }
    }
    
    var ingredientsSection: some View {
        var header: some View {
            Text(viewModel.ingredientsTitle)
        }
        
        return FormStyledSection(header: header) {
            IngredientsView(
                actionHandler: handleIngredientsAction
            )
            .environmentObject(viewModel)
        }
    }
    
    func handleIngredientsAction(_ action: IngredientsView.Action) {
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
