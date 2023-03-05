import SwiftUI
import SwiftUISugar
import FoodLabel
import PrepViews
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

public struct ItemForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused: Bool

    @ObservedObject var model: ItemFormModel

    @State var hasAppeared: Bool = false
    @State var bottomHeight: CGFloat = 0.0
    @State var showingDeleteConfirmation = false
    @State var showingQuantityForm = false
    
    @State var showingMealPicker = false

    let alreadyInNavigationStack: Bool
    let forIngredient: Bool
    let actionHandler: (ItemFormAction) -> ()

    public init(
        model: ItemFormModel,
        isEditing: Bool = false,
        forIngredient: Bool = false,
        actionHandler: @escaping ((ItemFormAction) -> ())
    ) {
        self.model = model
        self.actionHandler = actionHandler
        self.forIngredient = forIngredient
        alreadyInNavigationStack = !isEditing
    }
    
    public var body: some View {
        Group {
            if alreadyInNavigationStack {
                content
            } else {
                navigationStack
            }
        }
        .onAppear(perform: appeared)
        .sheet(isPresented: $showingMealPicker) { mealPicker }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation {
                hasAppeared = true
            }
        }
    }
    
    var navigationStack: some View {
        NavigationStack(path: $model.path) {
            content
                .background(background)
                .navigationDestination(for: ItemFormRoute.self, destination: navigationDestination)
        }
    }
    
    var content: some View {
        ZStack {
            scrollView
            saveLayer
        }
        .safeAreaInset(edge: .bottom) { Spacer().frame(height: 80) }
        .navigationTitle(model.navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showingQuantityForm) { quantityForm }
        .confirmationDialog(
            "",
            isPresented: $showingDeleteConfirmation,
            actions: { deleteConfirmationActions },
            message: { deleteConfirmationMessage }
        )
        .toolbar { trailingContent }
    }
    

    var deleteConfirmationActions: some View {
        Button("Delete \(model.entityName)", role: .destructive) {
            delete()
            actionHandler(.dismiss)
        }
    }

    var deleteConfirmationMessage: some View {
        Text("Are you sure you want to delete this \(model.entityName.lowercased())?")
    }

    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 2) {
                if model.isEditing {
                    deleteButton
                }
                closeButton
            }
        }
    }

    @ViewBuilder
    func navigationDestination(for route: ItemFormRoute) -> some View {
        switch route {
        case .food:
            ItemForm.FoodSearch(
                model: model,
                forIngredient: forIngredient,
                actionHandler: actionHandler
            )
        case .meal:
            mealPicker
        case .mealItemForm:
            EmptyView()
        }
    }
}
