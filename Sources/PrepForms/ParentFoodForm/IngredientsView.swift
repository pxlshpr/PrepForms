import SwiftUI
import PrepDataTypes
import SwiftHaptics

struct IngredientsView: View {
    
    @EnvironmentObject var viewModel: ParentFoodForm.ViewModel
    
    let actionHandler: (Action) -> ()
    
    var body: some View {
        content
    }
    
    var content: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                Cell(item: item)
                    .environmentObject(viewModel)
            }
            addMenu
        }
    }
    
    var addMenu: some View {
        Button {
            Haptics.feedback(style: .soft)
            actionHandler(.add)
        } label: {
            Text(viewModel.addTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.top, viewModel.isEmpty ? 0 : 12)
        }
    }
    
    enum Action {
        case add
    }
}

import PrepViews

extension IngredientsView {
    struct Cell: View {
        @Environment(\.colorScheme) var colorScheme
        
        @AppStorage(UserDefaultsKeys.showingFoodEmojis) var showingFoodEmojis = PrepConstants.DefaultPreferences.showingFoodEmojis
        @AppStorage(UserDefaultsKeys.showingFoodDetails) var showingFoodDetails = PrepConstants.DefaultPreferences.showingFoodDetails

        @EnvironmentObject var viewModel: ParentFoodForm.ViewModel
        
        let item: IngredientItem
    }
}

extension ParentFoodForm.ViewModel {
    func shouldShowDivider(for item: IngredientItem) -> Bool {
        /// if this is the last cell, never show it
//        if item.id == items.last?.id {
//            return false
//        }
        
//        /// If this cell is being targeted, don't show it
//        if dragTargetFoodItemId == item.id {
//            return false
//        }
        
        return true
    }
}

extension IngredientsView.Cell {
    var body: some View {
        content
            .background(listRowBackground)
    }
    
    var content: some View {
        HStack(spacing: 0) {
            optionalEmojiText
//                .padding(.leading, 10)
            nameTexts
                .padding(.leading, showingFoodEmojis ? 8 : 10)
                .padding(.top, viewModel.items.first?.id == item.id ? 0 : 12)
                .padding(.bottom, 12)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            foodBadge
                .transition(.scale)
//                .padding(.trailing, 10)
        }
    }
    
    @ViewBuilder
    var optionalEmojiText: some View {
        if showingFoodEmojis {
            Text(item.food.emoji)
                .font(.body)
        }
    }

    var nameTexts: some View {
        var view = Text(item.food.name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)
//        if showingFoodDetails {
        if true {
            if let detail = item.food.detail, !detail.isEmpty {
                view = view
                + Text(", ")
                    .font(.callout)
                    .foregroundColor(Color(.secondaryLabel))
                + Text(detail)
                    .font(.callout)
                    .foregroundColor(Color(.secondaryLabel))
            }
            if let brand = item.food.brand, !brand.isEmpty {
                view = view
                + Text(", ")
                    .font(.callout)
                    .foregroundColor(Color(.tertiaryLabel))
                + Text(brand)
                    .font(.callout)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        view = view
        + Text(" • ").foregroundColor(Color(.secondaryLabel))
        + Text(item.quantityDescription)
        
            .font(.callout)
            .fontWeight(.regular)
            .foregroundColor(.secondary)
        
        return view
            .multilineTextAlignment(.leading)
    }

    var foodBadge: some View {
        let widthBinding = Binding<CGFloat>(
            get: { item.badgeWidth },
            set: { _ in }
        )
        return FoodBadge(
            c: item.food.info.nutrients.carb,
            f: item.food.info.nutrients.fat,
            p: item.food.info.nutrients.protein,
            width: widthBinding
        )
    }
    
    
    var listRowBackground: some View {
        var color: Color {
            return colorScheme == .light
            ? Color(.secondarySystemGroupedBackground)
//            : Color(hex: "232323")
            : Color(hex: "2C2C2E")
        }
        
        var isLastCell: Bool {
            viewModel.items.last?.id == item.id
        }
        
        var divider: some View {
            Color(hex: colorScheme == .light
                  ? DiaryDividerLineColor.light
                  : DiaryDividerLineColor.dark
            )
            .frame(height: 0.18)
        }

        var separator: some View {
            Color(hex: colorScheme == .light
                  ? DiarySeparatorLineColor.light
                  : DiarySeparatorLineColor.dark
            )
            .frame(height: 0.18)
        }

        var background: some View {
            Color.white
                .colorMultiply(color)
        }

        return ZStack {
            background
            VStack {
                Spacer()
                if viewModel.shouldShowDivider(for: item) {
                    divider
                        .padding(.leading, 52)
                }
            }
        }
    }
}
