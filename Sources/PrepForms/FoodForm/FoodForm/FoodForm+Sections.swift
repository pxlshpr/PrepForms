import SwiftUI
import SwiftUISugar
import FoodLabel
import PrepDataTypes
import PrepViews
import SwiftHaptics

struct FoodDetailsCell: View {
    
    enum Action {
        case emoji
        case name
        case detail
        case brand
    }
    
    @EnvironmentObject var fields: FoodForm.Fields
    let foodType: FoodType
    let actionHandler: (Action) -> ()
    
    var namePlaceholder: String {
        "Name"
    }
    
    var body: some View {
        HStack {
            VStack {
                emojiButton
                Spacer()
            }
            detailsButtons
        }
        .foregroundColor(.primary)
    }
    
    var emojiButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            actionHandler(.emoji)
        } label: {
            Text(fields.emoji)
                .font(.system(size: 73))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemFill).gradient)
                )
                .padding(.trailing, 10)
        }
    }
    
    var detailPlaceholder: String {
        switch foodType {
        case .food:
            return "Flavor, Variety etc."
        case .recipe:
            return "Date Cooked, etc."
//            return "Description"
        case .plate:
            return "Description"
//            return "Description or Size"
        }
    }

    var brandPlaceholder: String {
        switch foodType {
        case .food:
            return "Brand, Supplier etc."
        case .recipe:
//            return "Website or Cookbook name"
            return "Source, Author etc."
        case .plate:
            return "More Details"
        }
    }

    var detailsButtons: some View {
        var nameButton: some View {
            var label: some View {
                Group {
                    if !fields.name.isEmpty {
                        Text(fields.name)
                            .foregroundColor(Color(.label))
                            .bold()
                    } else {
                        Text("Name")
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.secondarySystemFill).gradient)
                )
            }
            
            return Button {
                actionHandler(.name)
            } label: {
                label
            }
        }
        
        var detailButton: some View {
            var label: some View {
                Group {
                    if !fields.detail.isEmpty {
                        Text(fields.detail)
                            .foregroundColor(Color(.label))
                            .bold()
                    } else {
                        Text(detailPlaceholder)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.secondarySystemFill).gradient)
                )
            }
            
            return Button {
                actionHandler(.detail)
            } label: {
                label
            }
        }

        var brandButton: some View {
            var label: some View {
                Group {
                    if !fields.brand.isEmpty {
                        Text(fields.brand)
                            .foregroundColor(Color(.label))
                            .bold()
                    } else {
                        Text(brandPlaceholder)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.secondarySystemFill).gradient)
                )
            }
            
            return Button {
                actionHandler(.brand)
            } label: {
                label
            }
        }
        
        return HStack {
            VStack(alignment: .leading) {
                nameButton
                detailButton
                brandButton
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}

extension FoodForm {
    
    var detailsSection: some View {
        FormStyledSection(header: Text("Details")) {
            FoodDetailsCell(
                foodType: .food,
                actionHandler: handleDetailAction
            )
            .environmentObject(fields)
        }
    }
    
    func handleDetailAction(_ action: FoodDetailsCell.Action) {
        Haptics.feedback(style: .soft)
        switch action {
        case .emoji:
            showingEmojiPicker = true
        case .name:
            showingNameForm = true
        case .detail:
            showingDetailForm = true
        case .brand:
            showingBrandForm = true
        }
    }

    var sourcesSection: some View {
        SourcesSummaryCell(
            sources: sources,
            showingAddLinkAlert: $showingAddLinkAlert,
            didTapCamera: showExtractorViewWithCamera
        )
    }
    
    var foodLabelSection: some View {
        @ViewBuilder var header: some View {
            if !fields.shouldShowFoodLabel {
                Text("Nutrition Facts")
            }
        }
        
        return FormStyledSection(header: header) {
            NavigationLink {
                NutrientsList()
                    .environmentObject(fields)
                    .environmentObject(sources)
            } label: {
                if fields.shouldShowFoodLabel {
                    foodLabel
                } else {
                    Text("Required")
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    @ViewBuilder
    var prefillSection: some View {
        if let url = fields.prefilledFood?.sourceUrl {
            FormStyledSection(header: Text("Prefilled Food")) {
                NavigationLink {
                    WebView(urlString: url)
                } label: {
                    LinkCell(LinkInfo("https://myfitnesspal.com")!, title: "MyFitnessPal")
                }
            }
        }
    }
    
    var servingSection: some View {
        FormStyledSection(header: Text("Servings")) {
            NavigationLink {
                NutrientsPerForm(fields: fields)
            } label: {
                if fields.hasAmount {
                    servingsAndSizesCell
                } else {
                    Text("Required")
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

extension FoodForm {
    var detailsForm: some View {
        DetailsQuickForm()
            .environmentObject(fields)
    }
}


struct DetailsQuickForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fields: FoodForm.Fields
    
    @State var showingBrandForm = false
    @State var showingNameForm = false
    @State var showingDetailForm = false
    
    let brandLabel: String
    
    init(brandLabel: String = "Brand") {
        self.brandLabel = brandLabel
    }

    var body: some View {
        NavigationStack {
            form
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingNameForm) {
            DetailsNameForm(title: "Name", isRequired: true, name: $fields.name)
        }
        .sheet(isPresented: $showingDetailForm) {
            DetailsNameForm(title: "Detail", isRequired: false, name: $fields.detail)
        }
        .sheet(isPresented: $showingBrandForm) {
            DetailsNameForm(title: brandLabel, isRequired: false, name: $fields.brand)
        }
    }
    
    var form: some View {
        QuickForm(title: "Details", confirmButtonForDismiss: true) {
            FormStyledSection {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Name")
                            .foregroundColor(.secondary)
                        fieldButton(fields.name, isRequired: true) {
                            showingNameForm = true
                        }
                    }
                    GridRow {
                        Text("Detail")
                            .foregroundColor(.secondary)
                        fieldButton(fields.detail) {
                            showingDetailForm = true
                        }
                    }
                    GridRow {
                        Text("Brand")
                            .foregroundColor(.secondary)
                        fieldButton(fields.brand) {
                            showingBrandForm = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    func fieldButton(_ string: String, isRequired: Bool = false, action: @escaping () -> ()) -> some View {
        let fill: Color = colorScheme == .light
        ? Color(hex: "EFEFF0")
        : Color(.secondarySystemFill)
        
        return Button {
            Haptics.feedback(style: .soft)
            action()
        } label: {
            Text(!string.isEmpty ? string : (isRequired ? "Required" : "Optional"))
                .foregroundColor(!string.isEmpty ? .primary : Color(.tertiaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .foregroundColor(fill)
                )
        }
    }
}

struct DetailsQuickFormPreview: View {
    
    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                DetailsQuickForm()
                    .preferredColorScheme(.dark)
            }
    }
}

struct DetailsQuickForm_Previews: PreviewProvider {
    static var previews: some View {
        DetailsQuickFormPreview()
    }
}
