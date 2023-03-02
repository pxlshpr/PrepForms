import SwiftUI

extension FoodForm.AmountPerForm.DensityForm {
    var weightUnitPicker: some View {
        UnitPicker_Legacy(
            pickedUnit: field.value.weight.unit,
            filteredType: .weight)
        { unit in
            field.value.weight.unit = unit
            field.value.fill = .userInput
        }
        .environmentObject(fields)
    }
    
    var volumeUnitPicker: some View {
        UnitPicker_Legacy(
            pickedUnit: field.value.volume.unit,
            filteredType: .volume)
        { unit in
            field.value.volume.unit = unit
            field.value.fill = .userInput
        }
        .environmentObject(fields)
    }
}
