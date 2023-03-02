import SwiftUI
import PrepDataTypes
import SwiftHaptics

struct IngredientsCell: View {
    
    enum Action {
        case add
    }
    
    @EnvironmentObject var ingredients: Ingredients
    
    let actionHandler: (Action) -> ()
    
    var body: some View {
        content
    }
    
    var content: some View {
        VStack {
            addMenu
        }
    }
    
    var addMenu: some View {
        Button {
            Haptics.feedback(style: .soft)
            actionHandler(.add)
        } label: {
            Text("Add an ingredient")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
    }
}

extension IngredientsCell {
}
