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
import EmojiPicker

public struct ParentFoodForm: View {

    @StateObject var viewModel: ViewModel
    @StateObject var fields = FoodForm.Fields()
        
    @State var presentedSheet: Sheet? = nil
    @State var showingFoodLabel: Bool = false
    @State var showingCancelConfirmation = false

    @AppStorage(UserDefaultsKeys.showingIngredientEmojis) var showingIngredientEmojis = PrepConstants.DefaultPreferences.showingIngredientEmojis
    @AppStorage(UserDefaultsKeys.showingIngredientDetails) var showingIngredientDetails = PrepConstants.DefaultPreferences.showingIngredientDetails
    @AppStorage(UserDefaultsKeys.showingIngredientBadges) var showingIngredientBadges = PrepConstants.DefaultPreferences.showingIngredientBadges

    let shouldDismiss: () -> ()
    let id = UUID()
    
    public init(
        forRecipe: Bool,
        existingFood: Food? = nil,
        shouldDismiss: @escaping () -> ()
    ) {
        self.shouldDismiss = shouldDismiss
        
        let viewModel = ViewModel(forRecipe: forRecipe, existingFood: existingFood)
        _viewModel = StateObject(wrappedValue: viewModel)
        
        if let existingFood, let ingredientItems = existingFood.ingredientItems {
            _showingFoodLabel = State(initialValue: !ingredientItems.isEmpty)
        } else {
            _showingFoodLabel = State(initialValue: false)
        }
    }
    
    public var body: some View {
        let _ = Self._printChanges()
        return content
            .sheet(item: $presentedSheet) { sheet(for: $0) }
            .onChange(of: viewModel.sortOrder, perform: sortOrderChanged)
            .onChange(of: viewModel.items, perform: itemsChanged)
            .onChange(of: viewModel.itemsWithRecalculatedBadges, perform: itemsWithRecalculatedBadgesChanged)
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
    
    
    var formLayer: some View {
        FormStyledScrollView(showsIndicators: false, isLazy: false) {
            detailsSection
            if viewModel.forRecipe {
                servingSection
            }
            ingredientsSection
            foodLabel
            Spacer().frame(height: 60) /// to account for save button
        }
    }
    
    func itemsWithRecalculatedBadgesChanged(_ items: [IngredientItem]) {
        withAnimation(.interactiveSpring()) {
            viewModel.items = items
        }
    }
    
    func itemsChanged(_ items: [IngredientItem]) {
        withAnimation {
            showingFoodLabel = !items.isEmpty
        }
    }
    
    func sortOrderChanged(_ newSortOrder: IngredientSortOrder) {
        withAnimation {
            viewModel.resortItems()
        }
    }
    
    func handleItemAction(_ action: ItemFormAction, forEdit: Bool) {
        switch action {
        case .saveIngredientItem(let item):
            Haptics.successFeedback()
            if forEdit {
                viewModel.update(item)
                viewModel.recalculateBadgeWdiths(delay: 0)
            } else {
                withAnimation {
                    viewModel.add(item)
                }
                viewModel.recalculateBadgeWdiths()
            }
            
        case .delete:
//            Haptics.warningFeedback()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.interactiveSpring()) {
                    viewModel.removeEditingItem()
                }
                viewModel.recalculateBadgeWdiths()
            }

        case .dismiss:
            presentedSheet = nil
            
        default:
            break
        }
    }
    
    var foodLabel: some View {
        let dataBinding = Binding<FoodLabelData>(
            get: { foodLabelData },
            set: { _ in }
        )

        return Group {
            if showingFoodLabel {
                FormStyledSection {
                    FoodLabel(data: dataBinding)
                        .transition(.move(edge: .bottom))
                }
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
        
        return FormStyledSection(header: header, largeHeading: true) {
            IngredientsView(
                actionHandler: handleIngredientsAction
            )
            .environmentObject(viewModel)
        }
    }

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
                .imageScale(.medium)
                .fontWeight(.regular)
                .font(.title2)
//                .bold()

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
            viewModel.prepareForAdding()
            present(.foodSearch)
            
        case .tappedItem(let ingredientItem):
            viewModel.prepareForEditing(ingredientItem)
            present(.ingredientEdit)
        }
    }
    
    var detailsSection: some View {
        FormStyledSection(header: Text("Details"), largeHeading: false) {
            FoodDetailsCell(
                foodType: viewModel.forRecipe ? .recipe : .plate,
                actionHandler: handleDetailAction
            )
            .environmentObject(fields)
        }
    }
    
    func handleDetailAction(_ action: FoodDetailsCell.Action) {
        Haptics.feedback(style: .soft)
        switch action {
        case .emoji:
            present(.emoji)
        case .name:
            present(.name)
        case .detail:
            present(.detail)
        case .brand:
            present(.brand)
        }
    }
    
    var servingSection: some View {
        FormStyledSection(header: Text("Servings"), largeHeading: false) {
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
            
            if let uuid = UUID(uuidString: "fc9721cb-97c3-4dcb-8350-719e9b1c8c54"),
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
                shouldDismiss()
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
                shouldDismiss()
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
    
    enum Sheet: String, Identifiable {
        case name
        case detail
        case brand
        case emoji
        case foodSearch
        case ingredientEdit
        var id: String { rawValue }
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
