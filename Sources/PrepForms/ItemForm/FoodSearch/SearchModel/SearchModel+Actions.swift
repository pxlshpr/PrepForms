import SwiftUI
import PrepDataTypes

extension SearchModel {
    
    func search() {
        results = []
        currentPage = 1
        canLoadMorePages = true
        isLoadingPage = false
        loadMoreContent()
    }
    
    func loadMoreContentIfNeeded(currentResult result: FoodSearchResult?) {
        guard let result else {
            loadMoreContent()
            return
        }
        
        let thresholdIndex = results.index(results.endIndex, offsetBy: -10)
        if results.firstIndex(where: { $0.id == result.id }) == thresholdIndex {
            loadMoreContent()
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
            cprint("✨ Not loading more — isLoadingPage: \(isLoadingPage), canLoadMorePages: \(canLoadMorePages)")
            return
        }
        
        isLoadingPage = true
        
        Task {
            cprint("✨ Sending request for page: \(currentPage)")
//            let params = ServerFoodSearchParams(string: searchText, page: currentPage, per: 25)
//            let page = try await networkController.searchFoods(params: params)
//            await MainActor.run {
//                self.didReceive(page)
//            }
        }
    }
    
//    func didReceive(_ page: FoodsPage) {
//        if currentPage == 1 {
//            Haptics.successFeedback()
//        } else {
//            Haptics.feedback(style: .soft)
//        }
//
//        canLoadMorePages = page.hasMorePages
//        isLoadingPage = false
//
//        add(page.items)
//        currentPage += 1
//    }
    
    func add(_ newResults: [FoodSearchResult]) {
        /// Filter out the results that definitely don't exist in our current array before appending it (to avoid duplicates)
        let trulyNewResults = newResults.filter { newResult in
            !results.contains(where: { $0.id == newResult.id })
        }
        if currentPage == 1 {
            withAnimation {
                results.append(contentsOf: trulyNewResults)
            }
        } else {
            results.append(contentsOf: trulyNewResults)
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.getFoods(for: trulyNewResults)
//        }
    }
    
    func getFoods(for results: [FoodSearchResult]) {
        Task {
//            do {
//                let newFoods = try await networkController.foods(for: results)
//                foods.append(contentsOf: newFoods)
//            } catch {
//                cprint("Error getting foods: \(error)")
//            }
        }
    }
}
