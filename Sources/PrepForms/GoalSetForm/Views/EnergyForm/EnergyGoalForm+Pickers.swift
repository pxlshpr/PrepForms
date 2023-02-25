import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension EnergyGoalForm {
    
    @ViewBuilder
    var typePicker: some View {
        if goal.goalSetType == .meal {
            mealTypePicker
        } else {
            dietTypePicker
        }
    }
    
    var mealTypePicker: some View {
        PickerLabel(
            pickedMealEnergyGoalType.description(userEnergyUnit: viewModel.userUnits.energy),
            systemImage: nil
        )
            .animation(.none, value: pickedMealEnergyGoalType)
//        Menu {
//            Picker(selection: $pickedMealEnergyGoalType, label: EmptyView()) {
//                ForEach(MealEnergyTypeOption.allCases, id: \.self) {
//                    Text($0.description(userEnergyUnit: .kcal)).tag($0)
//                }
//            }
//        } label: {
//            PickerLabel(pickedMealEnergyGoalType.description(userEnergyUnit: .kcal))
//                .animation(.none, value: pickedMealEnergyGoalType)
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
    }
    
    var dietTypePicker: some View {
        let binding = Binding<DietEnergyTypeOption>(
            get: { pickedDietEnergyGoalType },
            set: { newType in
                withAnimation {
                    Haptics.feedback(style: .soft)
                    pickedDietEnergyGoalType = newType
                }
            }
        )
        return Menu {
            Picker(selection: binding, label: EmptyView()) {
                ForEach(DietEnergyTypeOption.allCases, id: \.self) {
                    Text($0.description(userEnergyUnit: viewModel.userUnits.energy)).tag($0)
                }
            }
        } label: {
            PickerLabel(pickedDietEnergyGoalType.shortDescription(userEnergyUnit: viewModel.userUnits.energy))
                .animation(.none, value: pickedDietEnergyGoalType)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }

    @ViewBuilder
    var deltaPicker: some View {
        if shouldShowEnergyDeltaElements {
            HStack {
                Menu {
                    Picker(selection: $pickedDelta, label: EmptyView()) {
                        ForEach(EnergyDeltaOption.allCases, id: \.self) {
                            Text($0.description).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(pickedDelta.description)
                        .animation(.none, value: pickedDelta)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }    
}
