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
    
    public enum Action {
        case dismiss
        case save(ParentFoodFormOutput)
    }
    
    class ViewModels: ObservableObject {
        static let shared = ViewModels()
        
        var objects: [(ViewModel, FoodForm.Fields)] = []
        
        func objects(at nestLevel: Int) -> (viewModel: ViewModel, fields: FoodForm.Fields)? {
            guard nestLevel < objects.count else {
                return nil
            }
            return objects[nestLevel]
        }
        
        func remove(at nestLevel: Int) {
            guard nestLevel < objects.count else { return }
            let _ = objects.remove(at: nestLevel)
        }
    }
    
    @StateObject var viewModel: ViewModel
    @StateObject var fields: FoodForm.Fields

    let actionHandler: (Action) -> ()
    let nestLevel: Int

    public init(
        nestLevel: Int = 0,
        forRecipe: Bool,
        existingFood: Food? = nil,
        actionHandler: @escaping (Action) -> ()
    ) {
        print("🐣 ParentFoodForm created with nestLevel: \(nestLevel)")
        self.nestLevel = nestLevel
        self.actionHandler = actionHandler
        
        /// If we already have a `ViewModel` and a `Field` for this `nestLevel`
        if let objects = ViewModels.shared.objects(at: nestLevel) {
            /// then we're being re-created and should simply grab those.
            _viewModel = StateObject(wrappedValue: objects.viewModel)
            _fields = StateObject(wrappedValue: objects.fields)
        } else {
            /// otherwise this is the first instantiation at this nestLevel, so create them
            let viewModel = ViewModel(forRecipe: forRecipe, existingFood: existingFood)
            _viewModel = StateObject(wrappedValue: viewModel)
            
            let fields = FoodForm.Fields()
            _fields = StateObject(wrappedValue: fields)
            
            /// Add the `@StateObject`s to the shared `ViewModels` that keeps a reference to them
            /// so that they may be reused upon re-creation.
            ViewModels.shared.objects.append((viewModel, fields))
        }
    }
    
    public var body: some View {
        content
            .sheet(item: $viewModel.presentedSheet) { sheet(for: $0) }
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
                saveButtonLayer
                    .zIndex(3)
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
            viewModel.showingFoodLabel = !items.isEmpty
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
            viewModel.presentedSheet = nil
            
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
            if viewModel.showingFoodLabel {
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
            get: { viewModel.showingEmojis },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    viewModel.showingEmojis = newValue
                    UserManager.showingIngredientsEmojis = newValue
                }
            }
        )

        let detailsBinding = Binding<Bool>(
            get: { viewModel.showingDetails },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    viewModel.showingDetails = newValue
                    UserManager.showingIngredientsDetails = newValue
                }
            }
        )

        let badgesBinding = Binding<Bool>(
            get: { viewModel.showingBadges },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    viewModel.showingBadges = newValue
                    UserManager.showingIngredientsBadges = newValue
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
                    Label("\(viewModel.showingEmojis ? "Showing" : "Hiding") Emojis", systemImage: "face.smiling")
                }
            }
            Picker(selection: detailsBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: detailsBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(viewModel.showingDetails ? "Showing" : "Hiding") Details", systemImage: "text.redaction")
                }
            }
            Picker(selection: badgesBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: badgesBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(viewModel.showingBadges ? "Showing" : "Hiding") Badges", systemImage: "align.horizontal.right.fill")
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
            viewModel.present(.foodSearch)
            
        case .tappedItem(let ingredientItem):
            viewModel.prepareForEditing(ingredientItem)
            viewModel.present(.ingredientEdit)
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
            viewModel.present(.emoji)
        case .name:
            viewModel.present(.name)
        case .detail:
            viewModel.present(.detail)
        case .brand:
            viewModel.present(.brand)
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
                        food: food.ingredientFood,
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
    
    func dismissWithHaptics() {
        Haptics.feedback(style: .soft)
        actionHandler(.dismiss)
    }
    
    var dismissButton: some View {
        var dismissConfirmationActions: some View {
            Button("Close without saving", role: .destructive) {
                dismissWithHaptics()
            }
        }
        
        var dismissConfirmationMessage: some View {
            Text("You have unsaved data. Are you sure?")
        }
        
        return Button {
            if fields.isDirty {
                Haptics.warningFeedback()
                viewModel.showingCancelConfirmation = true
            } else {
                dismissWithHaptics()
            }
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
        .confirmationDialog(
            "",
            isPresented: $viewModel.showingCancelConfirmation,
            actions: { dismissConfirmationActions },
            message: { dismissConfirmationMessage }
        )
    }
}

enum ParentFoodFormSheet: String, Identifiable {
    case name
    case detail
    case brand
    case emoji
    case foodSearch
    case ingredientEdit
    var id: String { rawValue }
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
