import Foundation
import PrepDataTypes

public struct FoodSearchResults {
    var isLoading: Bool = false
    var foods: [Food]? = nil
    
    var isLoadingPage = false
    var currentPage = 1
    var canLoadMorePages = true
}

