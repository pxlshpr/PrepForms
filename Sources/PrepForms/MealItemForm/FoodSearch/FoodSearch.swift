import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews
import PrepCoreDataStack

public struct FoodSearch: View {
    
    @Namespace var namespace
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss

    @State var wasInBackground: Bool = false
    @State var focusFakeKeyboardWhenVisible = false
    @FocusState var fakeKeyboardFocused: Bool

    @StateObject var searchViewModel: SearchViewModel
    @StateObject var searchManager: SearchManager

    @State var showingBarcodeScanner = false
    @State var showingFilters = false
    
    @State var searchingVerified = false
    @State var searchingDatasets = false
    
    @State var isComparing = false
    
    @State var hasAppeared: Bool
    @State var initialFocusCompleted: Bool = false
    
    @State var shouldShowRecents: Bool = true
    @State var shouldShowSearchPrompt: Bool = false
    
    @State var showingAddFood = false
    @State var showingAddPlate = false
    @State var showingAddRecipe = false

    @State var showingAddHeroButton: Bool
    @State var heroButtonOffsetOverride: Bool = false
    
    @State var initialSearchIsFocusedChangeIgnored: Bool = false
    
    @Binding var searchIsFocused: Bool

    let didTapClose: (() -> ())?
    let didTapFood: (Food) -> ()
    let didTapMacrosIndicatorForFood: (Food) -> ()
    
    let focusOnAppear: Bool
    let isRootInNavigationStack: Bool
    
    let didAddFood = NotificationCenter.default.publisher(for: .didAddFood)
    
    public init(
        dataProvider: SearchDataProvider,
        isRootInNavigationStack: Bool,
        shouldDelayContents: Bool = true,
        focusOnAppear: Bool = false,
        searchIsFocused: Binding<Bool>,
        didTapClose: (() -> ())? = nil,
        didTapFood: @escaping ((Food) -> ()),
        didTapMacrosIndicatorForFood: @escaping ((Food) -> ())
    ) {
        self.isRootInNavigationStack = isRootInNavigationStack
        
        let searchViewModel = SearchViewModel(recents: dataProvider.recentFoods)
        _searchViewModel = StateObject(wrappedValue: searchViewModel)
        
        let searchManager = SearchManager(
            searchViewModel: searchViewModel,
            dataProvider: dataProvider
        )
        _searchManager = StateObject(wrappedValue: searchManager)
        
        self.focusOnAppear = focusOnAppear
        
        //TODO: Replace this with a single action handler and an (associated) enum
        self.didTapClose = didTapClose
        self.didTapFood = didTapFood
        self.didTapMacrosIndicatorForFood = didTapMacrosIndicatorForFood
        
        _showingAddHeroButton = State(initialValue: focusOnAppear)
        _hasAppeared = State(initialValue: shouldDelayContents ? false : true)
        
        _searchIsFocused = searchIsFocused
    }
    
    var background: some View {
        FormBackground()
            .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    public var body: some View {
        content
        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                withAnimation(.interactiveSpring()) {
//                    hasAppeared = true
//                }
//            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                initialFocusCompleted = true
//            }
        }
        .transition(.opacity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingContent }
        .toolbar { principalContent }
        .toolbar { leadingContent }
        .onChange(of: searchViewModel.searchText, perform: searchTextChanged)
        .onChange(of: scenePhase, perform: scenePhaseChanged)
        .onChange(of: searchIsFocused, perform: searchIsFocusedChanged)
        .sheet(isPresented: $showingAddPlate) { plateFormSheet }
        .sheet(isPresented: $showingAddRecipe) { recipeFormSheet }
        .onReceive(didAddFood, perform: didAddFood)
    }
    
    @ViewBuilder
    var content: some View {
//        if !hasAppeared {
//            background
//        } else {
            ZStack {
//                list
                searchableView
//                addHeroLayer
                fakeTextField
            }
            .sheet(isPresented: $showingBarcodeScanner) { barcodeScanner }
            .sheet(isPresented: $showingFilters) { filtersSheet }
            .onChange(of: isComparing, perform: isComparingChanged)
            .background(background)
//        }
    }
    
    var foodForm: some View {
        
        func didSaveFood(_ formOutput: FoodFormOutput) {
            Haptics.successFeedback()
            FoodFormManager.shared.save(formOutput)
        }
        
        return FoodForm(isPresented: $showingAddFood, didSave: didSaveFood)
    }
    
    var plateFormSheet: some View {
        NavigationStack {
            FormStyledScrollView {
                FormStyledSection {
                    Button("Add Food") {
                        
                    }
                }
            }
            .navigationTitle("New Plate")
        }
    }

    var recipeFormSheet: some View {
        RecipeForm()
    }

    func hideHeroAddButton() {
        withAnimation {
            if showingAddHeroButton {
//                showingAddHeroButton = false
            }
        }
    }
    
    func didAddFood(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let food = userInfo[Notification.Keys.food] as? Food
        else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            didTapFood(food)
        }
    }
    
    func searchIsFocusedChanged(_ newValue: Bool) {
        if initialSearchIsFocusedChangeIgnored {
            hideHeroAddButton()
        } else {
            initialSearchIsFocusedChangeIgnored = true
        }
    }

    func scenePhaseChanged(to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            wasInBackground = true
//            searchIsFocused = false
        case .active:
            if wasInBackground, showingAddFood {
                focusFakeKeyboardWhenVisible = true
                wasInBackground = false
            }
        default:
            break
        }
    }
    
    var fakeTextField: some View {
        TextField("", text: .constant(""))
            .focused($fakeKeyboardFocused)
            .opacity(0)
    }

    func showingAddFoodChanged(_ showing: Bool) {
        guard !showing else { return }
        guard focusFakeKeyboardWhenVisible else { return }
        focusFakeKeyboardWhenVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fakeKeyboardFocused = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                fakeKeyboardFocused = false
            }
            /// failsafe in case it wasn't unfocused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                fakeKeyboardFocused = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                fakeKeyboardFocused = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                fakeKeyboardFocused = false
            }
        }
    }

    var addHeroLayer: some View {
        
        var bottomPadding: CGFloat {
            (searchIsFocused || !initialFocusCompleted) ? 65 + 5 : 65
        }
        
        var yOffset: CGFloat {
            heroButtonOffsetOverride
            ? K.keyboardHeight
            : 0
        }
        
        return VStack {
            Spacer()
            HStack {
                Spacer()
                if !showingAddHeroButton {
//                    addHeroButton
                    addHeroMenu
                        .offset(y: yOffset)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, bottomPadding)
    }
    
    var addFoodButton: some View {
        Button {
            FoodForm.Fields.shared.reset()
            FoodForm.Sources.shared.reset()
            FoodForm.ViewModel.shared.reset()
            
            /// Actually shows the `View` for the `FoodForm` that we were passed in
            showingAddFood = true

            /// Resigns focus on search and hides the hero button
            searchIsFocused = false
            showingAddHeroButton = false
            
        } label: {
            Label("Food", systemImage: FoodType.food.systemImage)
        }
    }

    var scanFoodLabelButton: some View {
        Button {
            FoodForm.Fields.shared.reset()
            FoodForm.Sources.shared.reset()
            FoodForm.ViewModel.shared.reset(startWithCamera: true)
            
            /// Actually shows the `View` for the `FoodForm` that we were passed in
            showingAddFood = true

            /// Resigns focus on search and hides the hero button
            searchIsFocused = false
            showingAddHeroButton = false
            
        } label: {
            Label("Scan Food Label", systemImage: "text.viewfinder")
        }
    }
    
    var addPlateButton: some View {
        Button {
        } label: {
            Label("Plate", systemImage: FoodType.plate.systemImage)
        }
    }
    
    var addRecipeButton: some View {
        Button {
//            showingAddRecipe = true
//            searchIsFocused = false
//            showingAddHeroButton = false
        } label: {
            Label("Recipe", systemImage: FoodType.recipe.systemImage)
        }
    }
    
    var addHeroMenu: some View {
        var label: some View {
            Image(systemName: "plus")
                .font(.system(size: 25))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    ZStack {
                        Circle()
                            .foregroundStyle(Color.accentColor.gradient)
                    }
                    .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                )
        }
        
        var menu: some View {
            Menu {
                Section("Create New") {
                    addFoodButton
                    addRecipeButton
                    addPlateButton
                }
                scanFoodLabelButton
            } label: {
                label
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.selectionFeedback()
            })
        }
        
        return ZStack {
            label
            menu
        }
    }
    var searchableView: some View {
        var content: some View {
//            ZStack {
                list
//                addHeroLayer
//            }
        }
        
        return SearchableView(
            searchText: $searchViewModel.searchText,
            promptSuffix: "Foods",
            focused: $searchIsFocused,
            focusOnAppear: false,
//            focusOnAppear: focusOnAppear,
            isHidden: $isComparing,
            showKeyboardDismiss: true,
//            showDismiss: false,
//            didTapDismiss: didTapClose,
            didSubmit: didSubmit,
            buttonViews: {
                EmptyView()
                scanButton
            },
            content: {
                content
            })
    }
    
    func searchTextChanged(to searchText: String) {
        hideHeroAddButton()
        withAnimation {
            shouldShowRecents = searchText.isEmpty
            shouldShowSearchPrompt = searchViewModel.hasNotSubmittedSearchYet && searchText.count >= 3
        }
        Task {
            await searchManager.performBackendSearch()
        }
    }

    @ViewBuilder
    var list: some View {
//        Text("hi")
//        Color.clear
        if shouldShowRecents {
            recentsList
        } else {
            resultsList
        }
    }

    var resultsList: some View {
        List {
            resultsContents
        }
        .scrollContentBackground(.hidden)
        .listStyle(.sidebar)
    }
    
    var recentsList: some View {
        List {
            emptySearchContents
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    var emptySearchContents: some View {
        Group {
            if !searchViewModel.recents.isEmpty {
                recentsSection
            } else if !searchViewModel.allMyFoods.isEmpty {
                allMyFoodsSection
            }
//            createSection
//            Section(header: Text("")) {
//                EmptyView()
//            }
        }
    }
    
    var createSection: some View {
        return Group {
            Section {
                Button {
                    searchIsFocused = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingAddFood = true
//                    }
//                    didTapAddFood()
                } label: {
                    Label("Create New Food", systemImage: "plus")
                }
//                Button {
//
//                } label: {
//                    Label("Scan a Food Label", systemImage: "text.viewfinder")
//                }
            }
            .listRowBackground(FormCellBackground())
        }
    }
    
    var allMyFoodsSection: some View {
        var header: some View {
            HStack {
                Text("My Foods")
            }
        }
        
        return Section(header: header) {
            Text("All my foods go here")
        }
    }
    
    var recentsSection: some View {
        var header: some View {
            HStack {
                Image(systemName: "clock")
                Text("Recents")
            }
        }
        
        return Section(header: header) {
            ForEach(searchViewModel.recents, id: \.self) { food in
                foodButton(for: food)
            }
        }
        .listRowBackground(FormCellBackground())
    }
    
    func tappedFood(_ food: Food) {
        if searchIsFocused {
//            didTapFood(food)
            searchIsFocused = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                didTapFood(food)
//                searchIsFocused = false
//            }
        } else {
            didTapFood(food)
        }
    }
    
    func foodButton(for food: Food) -> some View {
        Button {
            tappedFood(food)
        } label: {
            FoodCell(
                food: food,
                isSelectable: $isComparing,
                didTapMacrosIndicator: {
                    didTapMacrosIndicatorForFood(food)
                },
                didToggleSelection: { _ in
                }
            )
        }
    }
    
    var resultsContents: some View {
        Group {
            foodsSection(for: .backend)
            foodsSection(for: .verified)
//            foodsSection(for: .datasets)
            searchPromptSection
        }
    }
    
    @ViewBuilder
    func header(for scope: SearchScope) -> some View {
        switch scope {
        case .backend:
            Text("My Foods")
        case .verified, .verifiedLocal:
            verifiedHeader
        case .datasets:
            publicDatasetsHeader
        }
    }
    
    @ViewBuilder
    var searchPromptSection: some View {
        if shouldShowSearchPrompt {
//            Section {
            Button {
                didSubmit()
            } label: {
                Text("Tap search to find foods matching '\(searchViewModel.searchText)' in our databases.")
                        .foregroundColor(.secondary)
            }
            .listRowBackground(FormCellBackground())
//            }
        }
    }
    func foodsSection(for scope: SearchScope) -> some View {
        let results = searchViewModel.results(for: scope)
        return Group {
            if let foods = results.foods {
                Section(header: header(for: scope)) {
                    if foods.isEmpty {
                        if results.isLoading {
                            loadingCell
                        } else {
                            noResultsCell
                        }
                    } else {
                        ForEach(foods, id: \.self) {
                            foodButton(for: $0)
                        }
                        if results.isLoading {
                            loadingCell
                        } else if results.canLoadMorePages {
                            loadMoreCell {
                                searchManager.loadMoreResults(for: scope)
                            }
                        }
                    }
                }
                .listRowBackground(FormCellBackground())
            }
        }
    }
    
    var noResultsCell: some View {
        Text("No results")
            .foregroundColor(Color(.tertiaryLabel))
    }
    
    var verifiedHeader: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
//                .foregroundColor(.green)
                .foregroundColor(.accentColor)
                .imageScale(.large)
            Text("Verified Foods")
        }
    }

    var publicDatasetsHeader: some View {
        HStack {
            Image(systemName: "text.book.closed.fill")
                .foregroundColor(.secondary)
            Text("Public Datasets")
        }
    }
}

extension FoodSearch {
    var title: String {
        return isComparing ? "Select \(searchViewModel.foodType.description)s to Compare" : "Search"
    }
}
