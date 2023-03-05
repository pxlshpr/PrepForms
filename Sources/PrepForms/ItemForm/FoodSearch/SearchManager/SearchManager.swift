import SwiftUI
import PrepDataTypes
import SwiftSugar

public class SearchManager: ObservableObject {

    var searchModel: SearchModel
    
    let dataProvider: SearchDataProvider
    
    public init(searchModel: SearchModel, dataProvider: SearchDataProvider) {
        self.searchModel = searchModel
        self.dataProvider = dataProvider
    }
    
    var backendSearchTask: Task<Void, Error>? = nil
    var networkSearchTask: Task<Void, Error>? = nil

    func performBackendSearch() async {
        guard !searchModel.searchText.isEmpty else {
            await MainActor.run {
                searchModel.clearSearch()
            }
            return
        }
        
        backendSearchTask?.cancel()
        backendSearchTask = Task {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                try await self.search(scope: .backend, with: self.searchModel.searchText)
                try await self.search(scope: .verifiedLocal, with: self.searchModel.searchText)
                cprint("🔎 Backend Search completed in \(CFAbsoluteTimeGetCurrent()-start)s")
            } catch let error where error is CancellationError {
                cprint("🔎✋🏽 Backend Search was cancelled")
            } catch {
                cprint("🔎⚠️ Unhandled error during search: \(error)")
            }
        }
    }
    
    var supportedScopes: [SearchScope] {
//        [.verified, .datasets]
        [.verified]
    }

    func performNetworkSearch() async {
        networkSearchTask?.cancel()
        networkSearchTask = Task {
            try await withThrowingTaskGroup(of: Result<SearchScope, SearchError>.self) { group in
                for scope in supportedScopes {
                    group.addTask {
                        do {
                            try await self.search(scope: scope, with: self.searchModel.searchText)
                            return .success(scope)
                        } catch let error where error is CancellationError {
                            return .failure(.cancelled(scope))
                        } catch {
                            return .failure(.unhandledError(scope, error))
                        }
                    }
                }

                let start = CFAbsoluteTimeGetCurrent()

                var isCancelled = false
                for try await result in group {
                    switch result {
                    case .success(let scope):
                        cprint("🔎 Search Scope: \(scope) completed in \(CFAbsoluteTimeGetCurrent()-start)s")
                    case .failure(let searchError):
                        switch searchError {
                        case .cancelled(let scope):
                            cprint("🔎✋🏽 Search was cancelled during scope: \(scope)")
                            isCancelled = true
                        case .unhandledError(let scope, let error):
                            cprint("🔎⚠️ Unhandled error during \(scope) search: \(error)")
                        }
                    }
                }

                if !isCancelled {
                    cprint("🔎✅ Search completed in \(CFAbsoluteTimeGetCurrent()-start)s")
                }
            }
        }
    }

    func search(scope: SearchScope, with searchText: String) async throws {
        
        await MainActor.run {
            withAnimation {
                searchModel.setInitialLoadingState(for: scope)
            }
        }
        
        let (foods, haveMoreResults) = try await dataProvider.getFoods(
            scope: scope,
            searchText: searchText,
            page: 1
        )

        await MainActor.run {
            withAnimation {
                searchModel.addResults(
                    for: scope,
                    with: foods,
                    haveMoreResults: haveMoreResults
                )
            }
        }
    }
    
    func loadMoreResults(for scope: SearchScope) {
        searchModel.setLoadingState(for: scope)

        Task {
            let (foods, haveMoreResults) = try await dataProvider.getFoods(
                scope: scope,
                searchText: searchModel.searchText,
                page: searchModel.currentPage + 1
            )

            await MainActor.run {
                withAnimation {
                    searchModel.addResults(
                        for: scope,
                        with: foods,
                        haveMoreResults: haveMoreResults
                    )
                }
            }
        }
    }
}
