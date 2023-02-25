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

    @EnvironmentObject var sources: FoodForm.Sources
    @ObservedObject var fields: FoodForm.Fields

    @StateObject var viewModel = ViewModel()

    @State var shouldShowServing: Bool
    @State var shouldShowDensity: Bool

    @State var showingAmountForm = false
    @State var showingServingForm = false
    @State var showingSizeForm = false
    
    @State var showingImages: Bool = true
    
    init(fields: FoodForm.Fields) {
        self.fields = fields
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
            "Sizes give you additional portions to log this food in; like biscuit, bottle, container, etc."
        }
        
        return Group {
            titleCell("Sizes")
            ForEach(fields.allSizeFields, id: \.self) {
                sizeCell(for: $0)
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
    var amountCell: some View {
        var footerString: String {
            "This is how much of this food the nutrition facts are for."
        }
        
        return Group {
            Button {
                Haptics.feedback(style: .soft)
                showingAmountForm = true
            } label: {
                FieldCell(field: fields.amount, showImage: $showingImages)
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
                ? "You can"
                : "Enter this to"
            }
            if fields.isWeightBased {
                return "\(prefix) also log this food using volume units, like cups."
            } else {
                return "\(prefix) also log this food using using its weight."
            }
        }
        
        return Group {
            Button {
            } label: {
                FieldCell(field: fields.density, showImage: $showingImages)
                    .environmentObject(fields)
            }
            footerCell(footerString)
        }
    }

    func sizeCell(for sizeField: Field) -> some View {
        Button {
            
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
    
    var sizeForm: some View {
        sizeForm(for: viewModel.sizeFieldBeingEdited)
    }
    
    func sizeForm(for sizeField: Field?) -> some View {
        SizeForm(initialField: sizeField) { newSize in
            
        }
        .environmentObject(fields)
    }
}
