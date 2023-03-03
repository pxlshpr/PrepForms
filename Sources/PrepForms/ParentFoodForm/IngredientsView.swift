import SwiftUI
import PrepDataTypes
import SwiftHaptics

struct IngredientsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: ParentFoodForm.ViewModel
    
    let actionHandler: (Action) -> ()
    
    var body: some View {
        content
    }
    
    var content: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                Cell(item: item)
                    .environmentObject(viewModel)
            }
            addMenu
        }
    }
    
    var addMenu: some View {
        var legacyLabel: some View {
            Text(viewModel.addTitle)
        }
        
        var label: some View {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(viewModel.addTitle)
                    .fontWeight(.bold)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            actionHandler(.add)
        } label: {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.top, viewModel.isEmpty ? 0 : 12)
        }
    }
    
    enum Action {
        case add
    }
}
