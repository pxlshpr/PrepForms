import SwiftUI
import ActivityIndicatorView
import SwiftHaptics
import PrepDataTypes
import PrepViews

enum ResultGroupType {
    case myFoods
    case verified
    case datasets
}

struct ResultGroup {
    let type: ResultGroupType
    let results: [FoodSearchResult] = []
}

extension FoodSearch {
    
    var resultsContents_legacy: some View {
        Group {
            ForEach(searchViewModel.results) { result in
                Button {
                    Haptics.feedback(style: .soft)
                    searchIsFocused = false
                } label: {
                    FoodCell(result: result)
                        .buttonStyle(.borderless)
                }
                .onAppear {
                    searchViewModel.loadMoreContentIfNeeded(currentResult: result)
                }
            }
            if searchViewModel.isLoadingPage {
                HStack {
                    Spacer()
                    ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowSeparator(.hidden)
//                ProgressView()
            }
        }
    }
    
    var list_legacy: some View {
        List {
            resultsContents_legacy
        }
//        .safeAreaInset(edge: .bottom) {
//            Spacer().frame(height: 66)
//        }
        .listStyle(.plain)
    }
}

