import SwiftUI
import PrepDataTypes
import SwiftSugar

public class SearchModel: ObservableObject {
    
    public static let shared = SearchModel()
    @Published var searchText: String = ""
    @Published var foodType: FoodType = .food

    /// Recently used foods (or added) foods that are populated and kept up-to-date so they're always ready when the user presents this
    @Published var recents: [Food] = []
    @Published var allMyFoods: [Food] = []
    
    @Published var myFoodResults: FoodSearchResults = FoodSearchResults(isLoading: true, foods: [])
    @Published var verifiedLocalResults: FoodSearchResults = FoodSearchResults(isLoading: true, foods: [])
    @Published var verifiedResults: FoodSearchResults = FoodSearchResults()
    @Published var datasetResults: FoodSearchResults = FoodSearchResults()
    
    //MARK: - Legacy
    
    @Published var results = [FoodSearchResult]()
    
    @Published var isLoadingPage = false
    var currentPage = 1
    var canLoadMorePages = true
    
    public init(recents: [Food] = [], allMyFoods: [Food] = []) {
        self.recents = recents
        self.allMyFoods = allMyFoods
        NotificationCenter.default.addObserver(self, selector: #selector(didAddFood), name: .didAddFood, object: nil)
    }
    
    @objc func didAddFood(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let food = userInfo[Notification.Keys.food] as? Food
        else { return }
        withAnimation {
            self.recents.insert(food, at: 0)
        }
    }
    
    //TODO: Rename to setInitialLoadingState
    public func setInitialLoadingState(for scope: SearchScope) {
        switch scope {
        case .backend:
            /// Don't show loading indicator if we're searching the backend while we already have results
            /// (since this mostly happens during text entry, and we wouldn't want to constantly keep
            /// swapping the view)
            break
        case .verified:
            verifiedResults.isLoading = true
            verifiedResults.foods = verifiedLocalResults.foods
        case .datasets:
            datasetResults.isLoading = true
            datasetResults.foods = []
        case .verifiedLocal:
            break
        }
    }
    
    public func setLoadingState(for scope: SearchScope) {
        switch scope {
        case .backend:
            myFoodResults.isLoading = true
        case .verified:
            verifiedResults.isLoading = true
        case .datasets:
            datasetResults.isLoading = true
        case .verifiedLocal:
            verifiedLocalResults.isLoading = true
        }
    }
    
    public func addResults(for scope: SearchScope, with foods: [Food], haveMoreResults: Bool) {
        switch scope {
        case .backend:
            myFoodResults.foods = foods
            myFoodResults.isLoading = false
            myFoodResults.canLoadMorePages = haveMoreResults
        case .verified:
            if let existingFoods = verifiedResults.foods {
                //TODO: Make sure we're not adding duplicates here
                var foods = existingFoods + foods
                foods.removeDuplicateFoods()
                verifiedResults.foods = foods
            } else {
                verifiedResults.foods = foods
            }
            verifiedResults.isLoading = false
            verifiedResults.canLoadMorePages = haveMoreResults
        case .verifiedLocal:
            verifiedResults.foods = foods
            verifiedLocalResults.foods = foods
            verifiedResults.isLoading = false
            verifiedResults.canLoadMorePages = haveMoreResults
        case .datasets:
            datasetResults.foods = foods
            datasetResults.isLoading = false
            datasetResults.canLoadMorePages = haveMoreResults
        }
    }
    
    public func results(for scope: SearchScope) -> FoodSearchResults {
        switch scope {
        case .backend:
            return myFoodResults
        case .verified:
            return verifiedResults
        case .datasets:
            return datasetResults
        case .verifiedLocal:
            return verifiedLocalResults
        }
    }
    
    func clearSearch() {
        verifiedResults.clear()
        datasetResults.clear()
        
        myFoodResults.clear()
        myFoodResults.foods = []
        myFoodResults.isLoading = true
    }
    
    /// We determine this by examining the `FoodSearcResults` for both verified and datasets, and if they are both nil,
    /// we can conclude that the user hasn't submitted search yet (as they begin as nil and then get assigned empty arrays at least)
    var hasNotSubmittedSearchYet: Bool {
        verifiedResults.foods == nil && datasetResults.foods == nil
    }
    
    var hasResults: Bool {
        myFoodResults.foods?.isEmpty == false
        || verifiedResults.foods?.isEmpty == false
        || datasetResults.foods?.isEmpty == false
    }
}

extension FoodSearchResults {
    mutating func clear() {
        foods = nil
        currentPage = 1
        canLoadMorePages = true
        isLoading = false
    }
}

public extension Array where Element == Food {
    func removingDuplicateFoods() -> [Food] {
        var addedDict = [UUID: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0.id) == nil
        }
    }

    mutating func removeDuplicateFoods() {
        self = self.removingDuplicateFoods()
    }
}
