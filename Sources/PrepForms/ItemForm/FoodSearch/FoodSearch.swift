import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews
import PrepCoreDataStack

extension FoodSearch {
    public enum Action {
        case dismiss
        case tappedFood(Food)
        case tappedFoodBadge(Food)
        case tappedAddFood
    }
}

public struct FoodSearch: View {
    
    @Namespace var namespace
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss

    @State var wasInBackground: Bool = false
    @State var focusFakeKeyboardWhenVisible = false
    @FocusState var fakeKeyboardFocused: Bool

    @StateObject var searchModel: SearchModel
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
    
    @State var showingAddHeroButton: Bool
    @State var heroButtonOffsetOverride: Bool = false
    
    @State var initialSearchIsFocusedChangeIgnored: Bool = false
    
    @State var showingEmojis: Bool
    
    @Binding var searchIsFocused: Bool

    let actionHandler: (Action) -> ()

    let focusOnAppear: Bool
    let isRootInNavigationStack: Bool
    
    let didAddFood = NotificationCenter.default.publisher(for: .didAddFood)
    let didUpdateUser = NotificationCenter.default.publisher(for: .didUpdateUser)

    let shouldShowPlatesInFilter: Bool
    
    let id: UUID
    
    public init(
        id: UUID,
        dataProvider: SearchDataProvider,
        isRootInNavigationStack: Bool,
        shouldShowPlatesInFilter: Bool = true,
        shouldDelayContents: Bool = true,
        focusOnAppear: Bool = false,
        searchIsFocused: Binding<Bool>,
        actionHandler: @escaping (Action) -> ()
    ) {
        _showingEmojis = State(initialValue: UserManager.showingLogEmojis)
        
        self.id = id

        self.isRootInNavigationStack = isRootInNavigationStack
        self.shouldShowPlatesInFilter = shouldShowPlatesInFilter
        
        let searchModel = SearchModel(recents: dataProvider.recentFoods)
        _searchModel = StateObject(wrappedValue: searchModel)
        
        let searchManager = SearchManager(
            searchModel: searchModel,
            dataProvider: dataProvider
        )
        _searchManager = StateObject(wrappedValue: searchManager)
        
        self.focusOnAppear = focusOnAppear
        
        self.actionHandler = actionHandler
        
        _showingAddHeroButton = State(initialValue: focusOnAppear)
        _hasAppeared = State(initialValue: shouldDelayContents ? false : true)
        
        _searchIsFocused = searchIsFocused
    }
    
    @ViewBuilder
    public var body: some View {
        content
            .onAppear(perform: appeared)
            .transition(.opacity)
            .navigationTitle("Foods")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { trailingContent }
//            .toolbar { principalContent }
            .toolbar { leadingContent }
            .onChange(of: searchModel.searchText, perform: searchTextChanged)
            .onChange(of: searchIsFocused, perform: searchIsFocusedChanged)
            .onReceive(didAddFood, perform: didAddFood)
            .onReceive(didUpdateUser, perform: didUpdateUser)
            .sheet(isPresented: $showingBarcodeScanner) { barcodeScanner }
            .sheet(isPresented: $showingFilters) { filtersSheet }
            .onChange(of: isComparing, perform: isComparingChanged)
            .background(background)
    }
    
    @ViewBuilder
    var content: some View {
        SearchableView(
            searchText: $searchModel.searchText,
//            promptSuffix: "Foods",
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
                delayedList
            }
        )
    }
    
    var delayedList: some View {
        Group {
            if hasAppeared {
                list
            } else {
                Color.clear
                    .transition(.opacity)
            }
        }
    }
    
    var title: String {
        return isComparing ? "Select \(searchModel.foodType.description)s to Compare" : "Search"
    }
}
