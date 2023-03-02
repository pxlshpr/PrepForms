import SwiftUI
import SwiftUISugar
import SwiftHaptics

struct FiltersSheet: View {
    
    @StateObject var viewModel = FiltersSheetViewModel()

    init() { }
    
    var body: some View {
        NavigationView {
            FormStyledScrollView {
                FormStyledSection(header: Text("Types")) {
                    typesSection
                }
                FormStyledSection(header: Text("Public Datasets"), footer: footer) {
                    databasesSection
                }
            }
            .onAppear(perform: appeared)
            .navigationTitle("Search Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
    
    func appeared() {
        viewModel.footerText = viewModel.getFooterText()
    }
    
    var footer: some View {
        viewModel.footerText
    }
    
    var databasesSection: some View {
        FlowLayout(
            mode: .scrollable,
            items: viewModel.databaseFilters,
            itemSpacing: 4,
            shouldAnimateHeight: .constant(false)
        ) {
            databaseButton(for: $0)
        }
    }

    var typesSection: some View {
        FlowLayout(
            mode: .scrollable,
            items: viewModel.typeFilters,
            itemSpacing: 4,
            shouldAnimateHeight: .constant(false)
        ) {
            typeButton(for: $0)
        }
    }

    @ViewBuilder
    func databaseButton(for database: Filter) -> some View {
        if let index = viewModel.databaseFilters.firstIndex(where: { $0.id == database.id }) {
            FilterButton(
                filter: $viewModel.databaseFilters[index],
                onlyOneFilterSelectedInGroup: $viewModel.onlyOneDatabaseIsSelected) {
            }
            .buttonStyle(.borderless)
        }
    }
    
    @ViewBuilder
    func typeButton(for database: Filter) -> some View {
        if let index = viewModel.typeFilters.firstIndex(where: { $0.id == database.id }) {
            FilterButton(
                filter: $viewModel.typeFilters[index],
                onlyOneFilterSelectedInGroup: $viewModel.onlyOneTypeIsSelected) {
            }
            .buttonStyle(.borderless)
        }
    }

}

var allDatabases: [Filter] = [
//    Filter(
//        name: "Verified",
//        systemImage: "checkmark.seal",
//        selectedSystemImage: "checkmark.seal.fill",
//        selectedSystemImageColor: .blue,
//        isSelected: true
//    ),
//    Filter(
//        name: "Your Database",
//        systemImage: "person",
//        selectedSystemImage: "person.fill",
//        isSelected: true
//    ),
    Filter(
        name: "USDA",
        systemImage: "text.book.closed",
        selectedSystemImage: "text.book.closed.fill",
        isSelected: true
    ),
    Filter(
        name: "AUSNUT",
        systemImage: "text.book.closed",
        selectedSystemImage: "text.book.closed.fill",
        isSelected: true
    )
]

var allTypes: [Filter] = [
    Filter(
        name: "Foods",
        systemImage: "carrot",
        selectedSystemImage: "carrot.fill",
        isSelected: true
    ),
    Filter(
        name: "Recipes",
        systemImage: "note.text"
    ),
    Filter(
        name: "Plates",
        systemImage: "fork.knife"
    )
]

struct Filter: Identifiable {
    var id = UUID().uuidString
    var name: String
    var systemImage: String? = nil
    var selectedSystemImage: String? = nil
    var selectedSystemImageColor: Color? = nil
    var isSelected: Bool = false {
        didSet {
            Haptics.feedback(style: .soft)
        }
    }
    
    mutating func toggle() {
        Haptics.feedback(style: .soft)
        isSelected.toggle()
    }
}

struct FiltersSheetPreview: View {
    var body: some View {
        FiltersSheet()
    }
}

struct FiltersSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: .constant(true)) {
                    FiltersSheetPreview()
                }
        }
    }
}
