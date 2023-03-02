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

    @ObservedObject var viewModel: ViewModel

    @State var hasAppeared: Bool = false
    @State var bottomHeight: CGFloat = 0.0
    @State var showingDeleteConfirmation = false
    @State var showingQuantityForm = false

    let alreadyInNavigationStack: Bool
    let actionHandler: (ItemFormAction) -> ()

    public init(
        viewModel: ViewModel,
        isEditing: Bool = false,
        actionHandler: @escaping ((ItemFormAction) -> ())
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
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
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation {
                hasAppeared = true
            }
        }
    }
    
    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
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
        .navigationTitle(viewModel.navigationTitle)
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
        Button("Delete Entry", role: .destructive) {
            delete()
            actionHandler(.dismiss)
        }
    }

    var deleteConfirmationMessage: some View {
        Text("Are you sure you want to delete this entry?")
    }

    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 2) {
                if viewModel.isEditing {
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
                viewModel: viewModel,
                actionHandler: actionHandler
            )
        case .meal:
            mealPicker
        case .mealItemForm:
            EmptyView()
        }
    }
}
