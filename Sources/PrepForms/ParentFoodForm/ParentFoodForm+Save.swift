import SwiftUI
import SwiftHaptics

extension ParentFoodForm {
    
    var saveButtonLayer: some View {

        var size: CGFloat { 48 }
        var padding: CGFloat { 20 }
        
        var saveButton: some View {
            
            var isValid: Bool {
                !fields.name.isEmpty && model.items.count > 1
            }
            
            func didTapSave() {
                withAnimation {
                    model.showingSaveSheet.toggle()
                }
                if model.showingSaveSheet, !isValid {
                    Haptics.warningFeedback()
                } else {
                    Haptics.feedback(style: .soft)
                }
            }
            
            var label: some View {
                Image(systemName: "checkmark")
                    .font(.system(size: fontSize))
                    .fontWeight(.medium)
                    .foregroundColor(foregroundColor)
                    .frame(width: size, height: size)
                    .background(
                        ZStack {
                            Circle()
                                .foregroundStyle(.ultraThinMaterial)
                            Circle()
                                .foregroundStyle(Color.accentColor.gradient)
                                .opacity(isValid ? 1 : 0)
                        }
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                    )
            }
            
            var fontSize: CGFloat { 25 }

            var foregroundColor: Color {
                isValid
                ? .white
                : Color(.secondaryLabel)
            }
            
            return Button {
                didTapSave()
            } label: {
                label
            }
        }
        
        var layer: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    saveButton
//                        .offset(x: showingSaveButton ? 0 : size + padding)
                }
                .padding(.horizontal, padding)
                .padding(.bottom, 0)
            }
        }
        
        return layer
    }
    
    var saveSheetLayer: some View {
        saveSheet
    }
    
    var saveSheet: some View {
        func tappedSave() {
            let start = CFAbsoluteTimeGetCurrent()
            let fieldsAndItems = ParentFoodFormFieldsAndItems(fields: fields, model: model)
            guard let output = fieldsAndItems?.output else {
                return
            }
            print("ParentFood output took: \(CFAbsoluteTimeGetCurrent()-start)s")

            actionHandler(.save(output))
            dismissWithHaptics()
        }
        
        var validationMessage: ValidationMessage? {
            if fields.name.isEmpty {
                return .missingFields(["Name"])
            }
            if model.items.count < 2 {
                return .notEnoughIngredients
            }
            return nil
        }
        
        return SaveSheet(
            isPresented: $model.showingSaveSheet,
            validationMessage: Binding<ValidationMessage?>(
            get: { validationMessage },
            set: { _ in }
        ), didTapSave: {
            tappedSave()
        })
        .environmentObject(fields)
        .environmentObject(model)
    }
}

import PrepDataTypes

extension FoodSize {
    init?(formSize: FormSize) {
        guard let quantity = formSize.quantity,
              let value = formSize.foodValue
        else {
            return nil
        }
        
        self = FoodSize(
            name: formSize.name,
            volumePrefixExplicitUnit: formSize.volumePrefixUnit?.volumeUnit?.volumeExplicitUnit,
            quantity: quantity,
            value: value
        )
    }
}

struct ParentFoodFormFieldsAndItems {
    
    let name: String
    let emoji: String
    let detail: String?
    let brand: String?
    
    let amount: FieldValue
    let serving: FieldValue?
    let density: FieldValue?
    let sizes: [FieldValue]
    
    let model: ParentFoodForm.Model
    
    init?(fields: FoodForm.Fields, model: ParentFoodForm.Model) {
        self.name = fields.name
        self.emoji = fields.emoji
        self.detail = fields.detail
        self.brand = fields.brand
        self.amount = fields.amount.value
        self.serving = fields.serving.value
        self.density = fields.density.value
        self.sizes = fields.allSizeFields.map { $0.value }
        self.model = model
    }
    
    var output: ParentFoodFormOutput? {
        guard let createForm else { return nil }
        return ParentFoodFormOutput(
            createForm: createForm,
            items: model.items,
            forRecipe: model.forRecipe
        )
    }
    var createForm: UserFoodCreateForm? {
        guard let info = foodInfo else {
            return nil
        }
        return UserFoodCreateForm(
            id: UUID(),
            name: name,
            emoji: emoji,
            detail: detail,
            brand: brand,
            publishStatus: .hidden,
            info: info
        )
    }
    
    var foodInfo: FoodInfo? {
        guard let amountFoodValue = FoodValue(fieldValue: amount) else {
            return nil
        }
        let servingFoodValue: FoodValue?
        if let serving {
            servingFoodValue = FoodValue(fieldValue: serving)
        } else {
            servingFoodValue = nil
        }
        return FoodInfo(
            amount: amountFoodValue,
            serving: servingFoodValue,
            nutrients: foodNutrients,
            sizes: foodSizes,
            density: foodDensity,
            linkUrl: nil,
            prefilledUrl: nil,
            imageIds: nil,
            barcodes: [],
            spawnedUserFoodId: nil,
            spawnedPresetFoodId: nil
        )
    }
    
    var foodNutrients: FoodNutrients {
        FoodNutrients(
            energyInKcal: model.amount(for: .energy),
            carb: model.amount(for: .carb),
            protein: model.amount(for: .protein),
            fat: model.amount(for: .fat),
            micros: model.microsArray
        )
    }
    
    var foodSizes: [FoodSize] {
        sizes
            .compactMap({ $0.size })
            .compactMap { FoodSize(formSize: $0) }
    }
    
    var foodDensity: FoodDensity? {
        density?.densityValue?.foodDensity
    }

}
