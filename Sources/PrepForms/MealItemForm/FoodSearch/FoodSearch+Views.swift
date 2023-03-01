import SwiftUI
import SwiftHaptics
import ActivityIndicatorView
import Camera
import PrepDataTypes
import SwiftUISugar
import PrepViews

extension FoodSearch {

    @ViewBuilder
    var list: some View {
        if shouldShowRecents {
            recentsList
        } else {
            resultsList
        }
    }
    
    var background: some View {
        FormBackground()
            .edgesIgnoringSafeArea(.all)
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
                    actionHandler(.tappedAddFood)
//                        showingAddFood = true
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
    
    func foodButton(for food: Food) -> some View {
        Button {
            tappedFood(food)
        } label: {
            FoodCell(
                food: food,
                isSelectable: $isComparing,
                didTapMacrosIndicator: {
                    actionHandler(.tappedFoodBadge(food))
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
    
    //MARK: - Cells
    
    var loadingCell: some View {
        HStack {
            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                .frame(width: 27, height: 27)
                .foregroundColor(.secondary)
                .offset(y: -2)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    func loadMoreCell(_ action: @escaping (() -> ())) -> some View {
        Button {
            Haptics.feedback(style: .rigid)
            action()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 30))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.accentColor)
        }
        //        .buttonStyle(.borderless)
    }
    
    //MARK: - Buttons
    var scanButton: some View {
        Button {
            searchIsFocused = false
            showingBarcodeScanner = true
        } label: {
            Image(systemName: "barcode.viewfinder")
//            Image(systemName: "viewfinder.circle.fill")
                .imageScale(.large)
        }
    }
    
    var filterButton: some View {
        Button {
            showingFilters = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .imageScale(.large)
        }
    }
    
    //MARK: Sheets
    
    var filtersSheet: some View {
        FiltersSheet()
    }
    
    var barcodeScanner: some View {
        BarcodeScanner { barcodes in
            if let barcode = barcodes.first {
                searchViewModel.searchText = barcode.string
            }
        }
    }
    
    //MARK: - Toolbars
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if isRootInNavigationStack {
                closeButton
            }
        }
    }
    
//    var trailingContent: some ToolbarContent {
//        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            addMenu
//        }
//    }
//
//    var addMenu: some View {
//        var label: some View {
//            Image(systemName: "plus")
//                .frame(width: 50, height: 50, alignment: .trailing)
//        }
//
//        var addFoodButton: some View {
//            Button {
//                //TODO: Bring this back
//                /// Resigns focus on search and hides the hero button
//    //            searchIsFocused = false
//    //            showingAddHeroButton = false
//
//                didTapAddFood()
//
//            } label: {
//                Label("Food", systemImage: FoodType.food.systemImage)
//            }
//        }
//
//        var scanFoodLabelButton: some View {
//            Button {
//                //TODO: Bring this back
//    //            FoodForm.Fields.shared.reset()
//    //            FoodForm.Sources.shared.reset()
//    //            FoodForm.ViewModel.shared.reset(startWithCamera: true)
//    //
//    //            /// Actually shows the `View` for the `FoodForm` that we were passed in
//    //            showingAddFood = true
//    //
//    //            /// Resigns focus on search and hides the hero button
//    //            searchIsFocused = false
//    //            showingAddHeroButton = false
//            } label: {
//                Label("Scan Food Label", systemImage: "text.viewfinder")
//            }
//        }
//
//        var addPlateButton: some View {
//            Button {
//            } label: {
//                Label("Plate", systemImage: FoodType.plate.systemImage)
//            }
//        }
//
//        var addRecipeButton: some View {
//            Button {
//    //            showingAddRecipe = true
//    //            searchIsFocused = false
//    //            showingAddHeroButton = false
//            } label: {
//                Label("Recipe", systemImage: FoodType.recipe.systemImage)
//            }
//        }
//
//        return Menu {
//            Section("Create New") {
//                addFoodButton
//                addRecipeButton
//                addPlateButton
//            }
//            scanFoodLabelButton
//        } label: {
//            label
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.selectionFeedback()
//        })
//    }
    
    var principalContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Group {
                if isComparing {
                    Text(title)
                        .font(.headline)
                } else {
                    Menu {
                        Picker(selection: $searchViewModel.foodType, label: EmptyView()) {
                            ForEach(FoodType.allCases, id: \.self) {
                                Label("\($0.description)s", systemImage: $0.systemImage).tag($0)
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    } label: {
                        HStack {
                            Label("\(searchViewModel.foodType.description)s", systemImage: searchViewModel.foodType.systemImage)
                                .labelStyle(.titleAndIcon)
                            Image(systemName: "chevron.up.chevron.down")
                                .imageScale(.small)
                                .fontWeight(.medium)
                        }
                        .animation(.none, value: searchViewModel.foodType)
                    }
//                    Picker("", selection: $searchViewModel.foodType) {
//                        ForEach(FoodType.allCases, id: \.self) {
//
//                            Label("\($0.description)s", systemImage: $0.systemImage).tag($0)
//                                .labelStyle(.titleAndIcon)
//                        }
//                    }
//                    .pickerStyle(.menu)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded {
                        Haptics.feedback(style: .soft)
                    })
                }
            }
        }
    }
    
    var closeButton: some View {
        Button {
            tappedClose()
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
    }
    
    @ViewBuilder
    var compareButton: some View {
        if searchViewModel.hasResults {
            Button {
                tappedCompare()
            } label: {
                Label("Compare", systemImage: "rectangle.portrait.on.rectangle.portrait.angled\(isComparing ? ".fill" : "")")
            }
        }
    }
    
//    var addHeroMenu: some View {
//        var label: some View {
//            Image(systemName: "plus")
//                .font(.system(size: 25))
//                .fontWeight(.medium)
//                .foregroundColor(.white)
//                .frame(width: 48, height: 48)
//                .background(
//                    ZStack {
//                        Circle()
//                            .foregroundStyle(Color.accentColor.gradient)
//                    }
//                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
//                )
//        }
//
//        var menu: some View {
//            Menu {
//                Section("Create New") {
//                    addFoodButton
//                    addRecipeButton
//                    addPlateButton
//                }
//                scanFoodLabelButton
//            } label: {
//                label
//            }
//            .contentShape(Rectangle())
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.selectionFeedback()
//            })
//        }
//
//        return ZStack {
//            label
//            menu
//        }
//    }
//
//    var addHeroLayer: some View {
//
//        var bottomPadding: CGFloat {
//            (searchIsFocused || !initialFocusCompleted) ? 65 + 5 : 65
//        }
//
//        var yOffset: CGFloat {
//            heroButtonOffsetOverride
//            ? K.keyboardHeight
//            : 0
//        }
//
//        return VStack {
//            Spacer()
//            HStack {
//                Spacer()
//                if !showingAddHeroButton {
//                    //                    addHeroButton
//                    addHeroMenu
//                        .offset(y: yOffset)
//                        .transition(.opacity)
//                }
//            }
//            .padding(.horizontal, 20)
//        }
//        .padding(.bottom, bottomPadding)
//    }
}
