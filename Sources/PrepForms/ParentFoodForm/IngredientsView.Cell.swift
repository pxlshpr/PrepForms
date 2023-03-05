import SwiftUI
import SwiftHaptics
import PrepDataTypes
import PrepViews

extension IngredientsView {
    struct Cell: View {
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var model: ParentFoodForm.Model
        
        let item: IngredientItem
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
                .padding(.leading, model.showingEmojis ? 8 : 10)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if model.showingBadges {
                foodBadge
                    .transition(.scale)
//                    .padding(.trailing, 10)
            }
        }
        .padding(.top, model.items.first?.id == item.id ? 0 : 12)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    var optionalEmojiText: some View {
        if model.showingEmojis {
            Text(item.food.emoji)
                .font(.body)
        }
    }

    var nameTexts: some View {
        var view = Text(item.food.name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)
        if model.showingDetails {
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
        .opacity(item.energyInKcal == 0 ? 0 : 1)
    }
    
    
    var listRowBackground: some View {
        var color: Color {
            return colorScheme == .light
            ? Color(.secondarySystemGroupedBackground)
//            : Color(hex: "232323")
            : Color(hex: "2C2C2E")
        }
        
        var isLastCell: Bool {
            model.items.last?.id == item.id
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
//                if model.shouldShowDivider(for: item) {
                    divider
                        .padding(.leading, 32)
//                }
            }
        }
    }
}

extension ParentFoodForm.Model {
    func shouldShowDivider(for item: IngredientItem) -> Bool {
        items.last?.id != item.id
    }
}
