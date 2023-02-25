import SwiftUI

struct FilterButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var filter: Filter
    @Binding var onlyOneFilterSelectedInGroup: Bool
    let didTap: () -> ()
    
    var body: some View {
        toggle
//        button
    }
    
    var isOnlySelectedFilterInGroup: Bool {
        onlyOneFilterSelectedInGroup && filter.isSelected
    }
    
    var toggle: some View {
        let isOn = Binding<Bool>(
            get: {
                /// Always show as toggled if this is the only selected filter in the group
                guard !isOnlySelectedFilterInGroup else {
                    return true
                }
                return filter.isSelected
            },
            set: {
                guard !isOnlySelectedFilterInGroup else {
                    return
                }
                filter.isSelected = $0
            }
        )

        return Toggle(isOn: isOn) {
            HStack {
                optionalImage
                Text(filter.name)
            }
            .frame(height: 25)
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .tint(filter.isSelected ? .accentColor : .gray)
    }
    
    @ViewBuilder
    var optionalImage: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .foregroundColor(systemImageColor)
                .frame(height: 25)
        }
    }
    
    var button: some View {
        Button {
            withAnimation {
                filter.toggle()
            }
            didTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .foregroundColor(backgroundColor(for: colorScheme))
                HStack(spacing: 5) {
                    optionalImage
                    Text(filter.name)
                        .foregroundColor(filter.isSelected ? .white : .primary)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
            }
            .fixedSize(horizontal: true, vertical: true)
            .contentShape(Rectangle())
        }
//        .grayscale(filter.isSelected ? 1 : 0)
    }
    
    var systemImageColor: Color? {
        guard let selectedColor = filter.selectedSystemImageColor, filter.isSelected else {
            return nil
        }
        return selectedColor
    }
    
    var systemImage: String? {
        if filter.isSelected, let selectedSystemImage = filter.selectedSystemImage {
            return selectedSystemImage
        } else {
            return filter.systemImage
        }
    }
    
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        let selectionColorDark = Color(hex: "6c6c6c")
        let selectionColorLight = Color(hex: "959596")
        
        guard filter.isSelected else {
            return Color(.secondarySystemFill)
        }
        return colorScheme == .light ? selectionColorLight : selectionColorDark
    }
}

extension Array where Element == Filter {
    var selectedCount: Int {
        filter({ $0.isSelected }).count
    }
}
