import SwiftUI
import PrepCoreDataStack
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews
import FoodLabel

public struct ParentFoodForm: View {

    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: ViewModel
    @StateObject var fields = FoodForm.Fields()
    
    @State var showingCancelConfirmation = false

    @State var showingDetailsForm = false
    @State var showingEmojiPicker = false
    @State var showingFoodSearch = false
    
    @State var showingFoodLabel: Bool = false
    
    public init(forRecipe: Bool, existingFood: Food? = nil) {
        let viewModel = ViewModel(forRecipe: forRecipe, existingFood: existingFood)
        _viewModel = StateObject(wrappedValue: viewModel)
        
//        if let existingFood, let childrenFoods = existingFood.childrenFoods {
//            _showingFoodLabel = State(initialValue: existingFood.childrenFoods?.count > 1)
//        }
    }

    public var body: some View {
        content
            .sheet(isPresented: $showingDetailsForm) { detailsForm }
            .sheet(isPresented: $showingFoodSearch) { foodSearchForm }
            .onChange(of: viewModel.sortOrder, perform: sortOrderChanged)
    }
    
    func sortOrderChanged(_ newSortOrder: IngredientSortOrder) {
        withAnimation {
            viewModel.resortItems()
        }
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
        FormStyledScrollView(showsIndicators: false, isLazy: true) {
            detailsSection
            if viewModel.forRecipe {
                servingSection
            }
            ingredientsSection
            foodLabel
            Spacer().frame(height: 60) /// to account for save button
        }
    }
    
    var foodLabel: some View {
        let dataBinding = Binding<FoodLabelData>(
            get: {
                FoodLabelData(
                    energyValue: fields.energy.value.value ?? .init(amount: 0, unit: .kcal),
                    carb: fields.carb.value.double ?? 0,
                    fat: fields.fat.value.double ?? 0,
                    protein: fields.protein.value.double ?? 0,
                    nutrients: fields.microsDict,
                    quantityValue: fields.amount.value.double ?? 0,
                    quantityUnit: fields.amount.value.doubleValue.unitDescription
                )
            },
            set: { _ in }
        )

        return Group {
            if showingFoodLabel {
                FoodLabel(data: dataBinding)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom))
            }
        }
    }
    
    var ingredientsSection: some View {
        var header: some View {
            HStack {
                Text(viewModel.ingredientsTitle)
                Spacer()
                ingredientsMenu
            }
        }
        
        return FormStyledSection(header: header) {
            IngredientsView(
                actionHandler: handleIngredientsAction
            )
            .environmentObject(viewModel)
        }
    }
    
    @AppStorage(UserDefaultsKeys.showingIngredientEmojis) var showingIngredientEmojis = PrepConstants.DefaultPreferences.showingIngredientEmojis
    @AppStorage(UserDefaultsKeys.showingIngredientDetails) var showingIngredientDetails = PrepConstants.DefaultPreferences.showingIngredientDetails
    @AppStorage(UserDefaultsKeys.showingIngredientBadges) var showingIngredientBadges = PrepConstants.DefaultPreferences.showingIngredientBadges

    var ingredientsMenu: some View {
        let emojisBinding = Binding<Bool>(
            get: { showingIngredientEmojis },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    showingIngredientEmojis = newValue
                }
            }
        )

        let detailsBinding = Binding<Bool>(
            get: { showingIngredientDetails },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    showingIngredientDetails = newValue
                }
            }
        )

        let badgesBinding = Binding<Bool>(
            get: { showingIngredientBadges },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    showingIngredientBadges = newValue
                }
            }
        )

        return Menu {
            Picker(selection: emojisBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: emojisBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(showingIngredientEmojis ? "Showing" : "Hiding") Emojis", systemImage: "face.smiling")
                }
            }
            Picker(selection: detailsBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: detailsBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(showingIngredientDetails ? "Showing" : "Hiding") Details", systemImage: "text.redaction")
                }
            }
            Picker(selection: badgesBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: badgesBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(showingIngredientBadges ? "Showing" : "Hiding") Badges", systemImage: "align.horizontal.right.fill")
                }
            }
            Picker(selection: viewModel.sortBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: viewModel.sortBinding, label: EmptyView()) {
                        ForEach(IngredientSortOrder.allCases.filter { $0 != .none }, id: \.self) {
                            Label($0.description, systemImage: $0.systemImage)
                                .tag($0)
                        }
                    }
                } label: {
                    Label(viewModel.sortOrderTitle, systemImage: "arrow.up.arrow.down")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .frame(maxHeight: .infinity)
                .padding(.leading, 20)
//                .background(.green)
        }
        .textCase(.none)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
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
                debugFillButton
                dismissButton
            }
        }
    }
    
    var debugFillButton: some View {
        
        func debugFill() {
            let wordLengths = [4, 5, 6, 7, 8]
            let firstWordLength = wordLengths.randomElement()!
            let secondWordLength = wordLengths.randomElement()!

            let firstWord = String((0..<firstWordLength).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! })
            let secondWord = String((0..<secondWordLength).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! })

            let randomString = "\(firstWord) \(secondWord)"
            
            fields.name = randomString
            fields.energy.value = .energy(.init(double: 100, unit: .kcal))
            fields.protein.value = .macro(.init(macro: .protein, double: 20))
            fields.carb.value = .macro(.init(macro: .carb, double: 20))
            fields.fat.value = .macro(.init(macro: .fat, double: 20))
            withAnimation {
                fields.updateFormState()
            }
            
            if let uuid = UUID(uuidString: "013c751f-dcdd-4aa9-a285-718dca159a75"),
               let food = DataManager.shared.food(with: uuid)
            {
                for _ in 0...20 {
                    let item = IngredientItem(
                        id: UUID(),
                        food: food,
                        amount: .init(WeightQuantity(100, .g)),
                        sortPosition: 1,
                        isSoftDeleted: false,
                        badgeWidth: 0,
                        energyInKcal: 0,
                        parentFoodId: nil
                    )
                    viewModel.add(item)
                }
                viewModel.recalculateBadgeWdiths()
            }
            
            Haptics.feedback(style: .rigid)
        }
        
        return Button {
            debugFill()
        } label: {
            Image(systemName: "rectangle.and.pencil.and.ellipsis")
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
                showingCancelConfirmation = true
            } else {
                Haptics.feedback(style: .soft)
                dismiss()
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


enum IngredientSortOrder: String, CaseIterable {
    case none
    case name
    case energy
    case carbPortion
    case proteinPortion
    case fatPortion
    
    var description: String {
        switch self {
        case .none:
            return "None"
        case .name:
            return "Name"
        case .energy:
            return "Energy"
        case .carbPortion:
            return "Highest Carb"
        case .proteinPortion:
            return "Highest Protein"
        case .fatPortion:
            return "Highest Fat"
        }
    }
    var systemImage: String {
        switch self {
        case .none:
            return ""
        case .name:
            return "arrow.down"
        case .energy:
            return "flame"
        case .carbPortion:
            return "c.square.fill"
        case .proteinPortion:
            return "p.square.fill"
        case .fatPortion:
            return "f.square.fill"
        }
    }
}