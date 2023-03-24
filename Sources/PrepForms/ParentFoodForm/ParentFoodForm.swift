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
    
    @StateObject var model: Model
    @StateObject var fields: FoodForm.Fields

    let actionHandler: (Action) -> ()

    public init(
        forRecipe: Bool,
        existingFood: Food? = nil,
        actionHandler: @escaping (Action) -> ()
    ) {
        self.actionHandler = actionHandler
        
        let model = Model(forRecipe: forRecipe, existingFood: existingFood)
        _model = StateObject(wrappedValue: model)
        
        let fields = FoodForm.Fields()
        _fields = StateObject(wrappedValue: fields)
    }
    
    public var body: some View {
        content
            .sheet(item: $model.presentedSheet) { sheet(for: $0) }
            .onChange(of: model.sortOrder, perform: sortOrderChanged)
            .onChange(of: model.items, perform: itemsChanged)
            .onChange(of: model.itemsWithRecalculatedBadges, perform: itemsWithRecalculatedBadgesChanged)
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
                .navigationTitle(model.title)
                .toolbar { navigationTrailingContent }
        }
    }
    
    
    var formLayer: some View {
        FormStyledScrollView(showsIndicators: false, isLazy: false) {
            detailsSection
            if model.forRecipe {
                servingSection
            }
            ingredientsSection
            foodLabel
            Spacer().frame(height: 60) /// to account for save button
        }
    }
    
    func itemsWithRecalculatedBadgesChanged(_ items: [IngredientItem]) {
        withAnimation(.interactiveSpring()) {
            model.items = items
        }
    }
    
    func itemsChanged(_ items: [IngredientItem]) {
        withAnimation {
            model.showingFoodLabel = !items.isEmpty
        }
    }
    
    func sortOrderChanged(_ newSortOrder: IngredientSortOrder) {
        withAnimation {
            model.resortItems()
        }
    }
    
    func handleItemAction(_ action: ItemFormAction, forEdit: Bool) {
        switch action {
        case .saveIngredientItem(let item):
            Haptics.successFeedback()
            if forEdit {
                model.update(item)
                model.recalculateBadgeWdiths(delay: 0)
            } else {
                withAnimation {
                    model.add(item)
                }
                model.recalculateBadgeWdiths()
            }
            
        case .delete:
//            Haptics.warningFeedback()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.interactiveSpring()) {
                    model.removeEditingItem()
                }
                model.recalculateBadgeWdiths()
            }

        case .dismiss:
            model.presentedSheet = nil
            
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
            if model.showingFoodLabel {
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
                Text(model.ingredientsTitle)
                Spacer()
                ingredientsMenu
            }
        }
        
        return FormStyledSection(header: header, largeHeading: true) {
            IngredientsView(
                actionHandler: handleIngredientsAction
            )
            .environmentObject(model)
        }
    }

    var ingredientsMenu: some View {
        let emojisBinding = Binding<Bool>(
            get: { model.showingEmojis },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    model.showingEmojis = newValue
                    UserManager.showingIngredientsEmojis = newValue
                }
            }
        )

        let detailsBinding = Binding<Bool>(
            get: { model.showingDetails },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    model.showingDetails = newValue
                    UserManager.showingIngredientsDetails = newValue
                }
            }
        )

        let badgesBinding = Binding<Bool>(
            get: { model.showingBadges },
            set: { newValue in
                Haptics.feedback(style: .soft)
                withAnimation {
                    model.showingBadges = newValue
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
                    Label("\(model.showingEmojis ? "Showing" : "Hiding") Emojis", systemImage: "face.smiling")
                }
            }
            Picker(selection: detailsBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: detailsBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(model.showingDetails ? "Showing" : "Hiding") Details", systemImage: "text.redaction")
                }
            }
            Picker(selection: badgesBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: badgesBinding, label: EmptyView()) {
                        Text("Show").tag(true)
                        Text("Hide").tag(false)
                    }
                } label: {
                    Label("\(model.showingBadges ? "Showing" : "Hiding") Badges", systemImage: "align.horizontal.right.fill")
                }
            }
            Picker(selection: model.sortBinding, label: EmptyView()) {
                Menu {
                    Picker(selection: model.sortBinding, label: EmptyView()) {
                        ForEach(IngredientSortOrder.allCases.filter { $0 != .none }, id: \.self) {
                            Label($0.description, systemImage: $0.systemImage)
                                .tag($0)
                        }
                    }
                } label: {
                    Label(model.sortOrderTitle, systemImage: "arrow.up.arrow.down")
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
            model.prepareForAdding()
            model.present(.foodSearch)
            
        case .tappedItem(let ingredientItem):
            model.prepareForEditing(ingredientItem)
            model.present(.ingredientEdit)
        }
    }
    
    var detailsSection: some View {
        FormStyledSection(header: Text("Details"), largeHeading: false) {
            FoodDetailsCell(
                foodType: model.forRecipe ? .recipe : .plate,
                actionHandler: handleDetailAction
            )
            .environmentObject(fields)
        }
    }
    
    func handleDetailAction(_ action: FoodDetailsCell.Action) {
        Haptics.feedback(style: .soft)
        switch action {
        case .emoji:
            model.present(.emoji)
        case .name:
            model.present(.name)
        case .detail:
            model.present(.detail)
        case .brand:
            model.present(.brand)
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
    
//    var detailsForm: some View {
//        DetailsQuickForm(brandLabel: "Source")
//            .environmentObject(fields)
//    }

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
                    model.add(item)
                }
                model.recalculateBadgeWdiths()
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
                model.showingCancelConfirmation = true
            } else {
                dismissWithHaptics()
            }
        } label: {
            CloseButtonLabel()
        }
        .confirmationDialog(
            "",
            isPresented: $model.showingCancelConfirmation,
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
            return "High-Calorie"
        case .carbPortion:
            return "High-Carb"
        case .proteinPortion:
            return "High-Protein"
        case .fatPortion:
            return "High-Fat"
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
            return "c.square"
        case .proteinPortion:
            return "p.square"
        case .fatPortion:
            return "f.square"
        }
    }
}
