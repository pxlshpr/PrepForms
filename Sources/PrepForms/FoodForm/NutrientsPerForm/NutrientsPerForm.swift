import SwiftUI
import SwiftUISugar
import FoodLabelScanner
import PrepDataTypes
import SwiftHaptics

extension NutrientsPerForm {
    class ViewModel: ObservableObject {
        @Published var sizeFieldBeingEdited: Field? = nil
    }
}

struct NutrientsPerForm: View {

    @ObservedObject var fields: FoodForm.Fields

    @StateObject var viewModel = ViewModel()

    @State var shouldShowServing: Bool
    @State var shouldShowDensity: Bool

    @State var showingAmountForm = false
    @State var showingServingForm = false
    @State var showingSizeForm = false
    @State var showingDensityForm = false

    @State var showingImages: Bool = true
    
    let forIngredients: Bool
    
    init(fields: FoodForm.Fields, forIngredients: Bool = false) {
        self.fields = fields
        self.forIngredients = forIngredients
        self.shouldShowServing = fields.shouldShowServing
        self.shouldShowDensity = fields.shouldShowDensity
    }
    
    var body: some View {
        scrollView
//        .toolbar { navigationTrailingContent }
        .navigationTitle("Servings and Sizes")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAmountForm) { amountForm }
        .sheet(isPresented: $showingServingForm) { servingForm }
        .sheet(isPresented: $showingSizeForm) { sizeForm }
        .sheet(isPresented: $showingDensityForm) { densityForm }
    }
    
    var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                amountCell
                if shouldShowServing {
                    servingCell
//                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .scale))
                }
                if shouldShowDensity {
                    densityCell
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .scale))
                }
                sizesGroup
            }
            .padding(.horizontal, 20)
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: 60)
            }
        }
        .scrollContentBackground(.hidden)
        .background(
            FormBackground()
                .edgesIgnoringSafeArea(.all)
        )
    }
    
    var sizesGroup: some View {
        var footerString: String {
            let examples = forIngredients
            ? "bowl, small tupperware, shaker bottle, etc."
            : "biscuit, bottle, container, etc."
            return "Sizes give you additional portions to log this \(foodType) in; like \(examples)"
        }
        
        return Group {
            titleCell("Sizes")
            ForEach(fields.allSizeFields.indices, id: \.self) {
                sizeCell(for: fields.allSizeFields[$0])
            }
            addSizeButton
            footerCell(footerString)
        }
    }
    
    var addSizeButton: some View {
        Button {
            viewModel.sizeFieldBeingEdited = nil
            showingSizeForm = true
        } label: {
            Text("Add a size")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.bottom, 13)
                .padding(.top, 13)
                .background(FormCellBackground())
                .cornerRadius(10)
                .padding(.bottom, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
    
    func titleCell(_ title: String) -> some View {
        Group {
            Spacer().frame(height: 15)
            HStack {
                Spacer().frame(width: 3)
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
            }
            Spacer().frame(height: 7)
        }
    }

    func footerCell(_ title: String) -> some View {
        Group {
//            Spacer().frame(height: 5)
            HStack {
                Spacer().frame(width: 3)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 17)
            .offset(y: -3)
            Spacer()
                .frame(height: 12)
        }
    }
    
    var foodType: String {
        forIngredients ? "recipe" : "food"
    }
    
    var amountCell: some View {
        var footerString: String {
            let object = forIngredients ? "ingredients" : "nutrition facts"
            return "This is how much of this \(foodType) the \(object) are for."
        }
        
        return Group {
            Button {
                Haptics.feedback(style: .soft)
                showingAmountForm = true
            } label: {
                FieldCell(
                    field: fields.amount,
                    showImage: $showingImages,
                    customTitle: forIngredients ? "Ingredients Per" : nil
                )
                .environmentObject(fields)
            }
            footerCell(footerString)
        }
    }

    var servingCell: some View {
        var footerString: String {
            if fields.serving.value.isEmpty {
                return "This is the size of 1 serving."
            }
            
            switch fields.serving.value.doubleValue.unit {
            case .weight:
                return "This is the weight of 1 serving."
            case .volume:
                return "This is the volume of 1 serving."
            case .size:
                return "This is the size of 1 serving."
//                return "This is how many \(size.prefixedName) 1 serving has."
//                return "This is how many \(size.prefixedName) is 1 serving."
            case .serving:
                return "Unsupported"
            }
        }

        return Group {
            Button {
                Haptics.feedback(style: .soft)
                showingServingForm = true
            } label: {
                FieldCell(field: fields.serving, showImage: $showingImages)
                    .environmentObject(fields)
            }
            footerCell(footerString)
        }
    }

    var densityCell: some View {
        var footerString: String {
            var prefix: String {
                return fields.density.isValid
                ? "You can now also"
                : "Enter this to also be able to"
            }
            if fields.isWeightBased {
                return "\(prefix) log this \(foodType) using volume units, like cups."
            } else {
                return "\(prefix) log this \(foodType) using using its weight."
            }
        }
        
        return Group {
            Button {
                showingDensityForm = true
            } label: {
                FieldCell(field: fields.density, showImage: $showingImages)
                    .environmentObject(fields)
            }
            footerCell(footerString)
        }
    }

    func sizeCell(for sizeField: Field) -> some View {
        Button {
            viewModel.sizeFieldBeingEdited = sizeField
            showingSizeForm = true
        } label: {
            FieldCell(field: sizeField, showImage: $showingImages)
                .environmentObject(fields)
        }
    }
}

extension NutrientsPerForm {
    var amountForm: some View {
        ServingForm(
            isServingSize: false,
            initialField: fields.amount,
            handleNewValue: { tuple in
                handleNewAmount(tuple?.0, unit: tuple?.1)
            }
        )
        .environmentObject(fields)
    }
    
    var servingForm: some View {
        ServingForm(
            isServingSize: true,
            initialField: fields.serving,
            handleNewValue: { tuple in
                handleNewServing(tuple?.0, unit: tuple?.1)
            }
        )
        .environmentObject(fields)
    }

    func handleNewAmount(_ double: Double?, unit: FormUnit?) {
        withAnimation {
            if let double, let unit {
                fields.amount.value.doubleValue.double = double
                fields.amount.value.doubleValue.unit = unit
            } else {
                fields.amount.value.doubleValue.double = nil
            }
            
            fields.amount.registerUserInput()
            fields.updateShouldShowDensity()
            shouldShowServing = fields.shouldShowServing
            shouldShowDensity = fields.shouldShowDensity
        }
    }
    
    func handleNewServing(_ double: Double?, unit: FormUnit?) {
        withAnimation {
            if let double, let unit {
                fields.serving.value.doubleValue.double = double
                fields.serving.value.doubleValue.unit = unit
            } else {
                fields.serving.value.doubleValue.double = nil
            }
            
            fields.serving.registerUserInput()
            fields.updateShouldShowDensity()
            shouldShowServing = fields.shouldShowServing
            shouldShowDensity = fields.shouldShowDensity
        }
    }

}

extension NutrientsPerForm {
    
    var densityForm: some View {
        DensityForm(initialField: fields.density) { density in
            guard let density else {
                fields.density = Field(fieldValue: .density(.init()))
                return
            }
            withAnimation {
                fields.density = Field(fieldValue: .density(.init(foodDensity: density)))
            }
        }
        .environmentObject(fields)
    }
    
    var sizeForm: some View {
        sizeForm(for: viewModel.sizeFieldBeingEdited)
    }
    
    func sizeForm(for sizeField: Field?) -> some View {
        SizeForm(initialField: sizeField) { size in
            saveSize(size)
        }
        .environmentObject(fields)
    }
    
    func saveSize(_ size: FormSize) {
        let field = Field.sizeField(with: size)
        withAnimation {
            if let oldSizeField = viewModel.sizeFieldBeingEdited {
                fields.edit(oldSizeField, with: field)
                viewModel.sizeFieldBeingEdited = nil
            } else {
                let _ =  fields.add(sizeField: field)
            }
            fields.updateFormState()
        }
    }
}

extension Field {
    static func sizeField(with size: FormSize) -> Field {
        Field(fieldValue: .size(.init(size: size, fill: .userInput)))
    }
}
