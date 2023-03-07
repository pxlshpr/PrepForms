import SwiftUI
import SwiftUISugar
import PrepDataTypes

extension GoalSetForm {
    struct Wizard: View {
        @Environment(\.colorScheme) var colorScheme
        @Binding var isPresented: Bool
        let type: GoalSetType
        var tapHandler: ((Action) -> Void)
        
        enum Action {
            case background
            case dismiss
            case empty
            case template(GoalSet)
        }
    }
}

extension GoalSetForm.Wizard {
    
    var body: some View {
        ZStack {
            VStack {
                clearLayer
                formLayer
                clearLayer
            }
            VStack {
                Spacer()
                cancelButton
            }
            .edgesIgnoringSafeArea(.all)
        }
        .zIndex(10)
        .edgesIgnoringSafeArea(.all)
        .offset(y: isPresented ? 0 : UIScreen.main.bounds.height)
    }
    
    var cancelButton: some View {
        Button {
            tapHandler(.dismiss)
        } label: {
            Text("Cancel")
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .foregroundStyle(.ultraThinMaterial)
                    //                        .foregroundStyle(colorScheme == .dark ? .ultraThinMaterial : .ultraThinMaterial)
                    //                        .foregroundColor(formCellBackgroundColor(colorScheme: colorScheme))
                    //                        .foregroundColor(formCellBackgroundColor(colorScheme: colorScheme))
                        .cornerRadius(15)
                        .shadow(color: colorScheme == .dark ? .black : .gray.opacity(0.75),
                                radius: 30, x: 0, y: 0)
                )
                .padding(.horizontal, 38)
                .padding(.bottom, 55)
                .contentShape(Rectangle())
        }
    }
    
    var formLayer: some View {
        
        var manualSection: some View {
            FormStyledSection(header: HStack {
                Text("Or Start From Scratch")
            }) {
                Button {
                    tapHandler(.empty)
                } label: {
                    Label("Empty \(type == .day ? "Diet" : "Meal Type")", systemImage: "square.and.pencil")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        var scanSection: some View {
            var title: some View {
                Text("Start with a template")
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.footnote)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
            
            var templates: some View {
                var templates: [GoalSet] {
                    type == .day ? TemplateDiets : TemplateMealTypes
                }
                
                func button(_ goalSet: GoalSet) -> some View {
                    var label: some View {
                        HStack {
                            Text(goalSet.emoji)
                            Text(goalSet.name)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.15))
                        )
                    }
                    
                    return Button {
                        tapHandler(.template(goalSet))
                    } label: {
                        label
                    }
                }
                
                var flowLayout: some View {
                    FlowLayout(
                        mode: .scrollable,
                        items: templates,
                        itemSpacing: 4,
                        shouldAnimateHeight: .constant(false)
                    ) { goalSet in
                        button(goalSet)
                    }
                }
                
//                return vStack
                return flowLayout
            }
            
            var footer: some View {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                        .shimmering()
                    Text("using our \(Text("Smart Food Label Scanner").fontWeight(.medium).foregroundColor(.primary)) to automagically fill it in.")
                        .font(.system(.footnote, design: .rounded, weight: .regular))
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 5)
            }
            
            return VStack(spacing: 7) {
                title
                templates
//                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        
        var zStack: some View {
            ZStack {
                FormBackground()
                VStack {
                    scanSection
                    manualSection
                }
                .padding(.vertical, 10)
            }
        }
        
        return zStack
            .cornerRadius(20)
            .frame(height: 280)
            .frame(maxWidth: 350)
            .padding(.horizontal, 30)
            .shadow(color: colorScheme == .dark ? .black : .gray.opacity(0.6), radius: 30, x: 0, y: 0)
            .offset(y: 40)
    }
    
    var clearLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                tapHandler(.background)
            }
    }
}

var TemplateDiets: [GoalSet] {
    
    let cutting = GoalSet(
        type: .day,
        name: "Cutting",
        emoji: "⬇️",
        goals: [
            Goal(type: .energy(.fromMaintenance(.kcal, .deficit)),
                 lowerBound: 500, upperBound: 750
            ),
            Goal(type: .macro(.quantityPerBodyMass(.weight, .kg), .protein),
                 lowerBound: 2.2, upperBound: 3
            ),
            Goal(type: .macro(.percentageOfEnergy, .fat),
                 lowerBound: 20, upperBound: 30
            ),
        ]
    )
    let bulking = GoalSet(
        type: .day,
        name: "Bulking",
        emoji: "⬆️",
        goals: [
            Goal(type: .energy(.percentFromMaintenance(.surplus)),
                 lowerBound: 10, upperBound: 20
            ),
            Goal(type: .macro(.quantityPerBodyMass(.weight, .kg), .protein),
                 lowerBound: 2, upperBound: 2.5
            ),
            Goal(type: .macro(.quantityPerBodyMass(.weight, .kg), .fat),
                 lowerBound: 0.5, upperBound: 2
            ),
        ]
    )
    let keto = GoalSet(
        type: .day,
        name: "Keto",
        emoji: "🥑",
        goals: [
            Goal(type: .energy(.percentFromMaintenance(.surplus)),
                 lowerBound: nil, upperBound: 10
            ),
            Goal(type: .macro(.percentageOfEnergy, .fat),
                 lowerBound: 70, upperBound: nil
            ),
            Goal(type: .macro(.percentageOfEnergy, .protein),
                 lowerBound: 20, upperBound: nil
            ),
        ]
    )
    let highProteinKeto = GoalSet(
        type: .day,
        name: "High Protein",
        emoji: "🍗",
        goals: [
            Goal(type: .energy(.percentFromMaintenance(.surplus)),
                 lowerBound: nil, upperBound: 10
            ),
            Goal(type: .macro(.percentageOfEnergy, .fat),
                 lowerBound: 60, upperBound: nil
            ),
            Goal(type: .macro(.percentageOfEnergy, .protein),
                 lowerBound: 35, upperBound: nil
            ),
        ]
    )
    let lowCarb = GoalSet(
        type: .day,
        name: "Low Carb",
        emoji: "📉",
        goals: []
    )
    let cheatDay = GoalSet(
        type: .day,
        name: "Cheat Day",
        emoji: "🍕",
        goals: [
            Goal(type: .energy(.percentFromMaintenance(.surplus)),
                 lowerBound: nil, upperBound: 75
            ),
            Goal(type: .micro(.percentageOfEnergy, .sugars, .g),
                 lowerBound: nil, upperBound: 35
            ),
        ]
    )
    let rda = GoalSet(
        type: .day,
        name: "Recommended",
        emoji: "🧑🏽‍⚕️",
        goals: [
        ]
    )


    return [rda, cutting, bulking, lowCarb, cheatDay, keto, highProteinKeto]
}

var TemplateMealTypes: [GoalSet] {
    let breakfast = GoalSet(
        type: .day,
        name: "Breakfast",
        emoji: "🍳",
        goals: [
            Goal(type: .macro(.fixed, .protein),
                 lowerBound: 25, upperBound: nil
            ),
            Goal(type: .macro(.fixed, .carb),
                 lowerBound: nil, upperBound: 50
            ),
            Goal(type: .micro(.fixed, .dietaryFiber, .g),
                 lowerBound: 10, upperBound: nil
            ),
        ]
    )
    let snack = GoalSet(
        type: .meal,
        name: "Snack",
        emoji: "🥨",
        goals: [
            Goal(type: .energy(.fixed(.kcal)),
                 lowerBound: 150, upperBound: 300
            ),
            Goal(type: .micro(.fixed, .sugars, .g),
                 lowerBound: nil, upperBound: 20
            )
        ]
    )
    let preWorkout = GoalSet(
        type: .meal,
        name: "Pre-workout",
        emoji: "🚴🏽",
        goals: [
            Goal(type: .macro(.quantityPerBodyMass(.weight, .kg), .carb),
                 lowerBound: 1, upperBound: nil
            ),
            Goal(type: .micro(.fixed, .caffeine, .mg),
                 lowerBound: 150, upperBound: 300
            ),
        ]
    )
    let postWorkout = GoalSet(
        type: .meal,
        name: "Post-workout",
        emoji: "🚴🏽",
        goals: [
            Goal(type: .macro(.fixed, .protein),
                 lowerBound: 20, upperBound: nil
            ),
            Goal(type: .micro(.quantityPerWorkoutDuration(.hour), .sodium, .mg),
                 lowerBound: 500, upperBound: 700
            ),
        ]
    )
    let cheatMeal = GoalSet(
        type: .meal,
        name: "Cheat Meal",
        emoji: "🍕",
        goals: [
            Goal(type: .energy(.fixed(.kcal)),
                 lowerBound: nil, upperBound: 1500
            ),
            Goal(type: .micro(.fixed, .sugars, .g),
                 lowerBound: nil, upperBound: 100
            )
        ]
    )
//    let preFast = GoalSet(
//        type: .meal,
//        name: "Pre-fast",
//        emoji: "🫄",
//        goals: []
//    )
//    let postFast = GoalSet(
//        type: .meal,
//        name: "Post-fast",
//        emoji: "🤤",
//        goals: []
//    )
//    let dessert = GoalSet(
//        type: .meal,
//        name: "Dessert",
//        emoji: "🍰",
//        goals: [
//            Goal(type: .energy(.fixed(.kcal)),
//                 lowerBound: nil, upperBound: 500
//            ),
//            Goal(type: .micro(.fixed, .sugars, .g),
//                 lowerBound: nil, upperBound: 100
//            )
//        ]
//    )
    return [snack, breakfast, cheatMeal, preWorkout, postWorkout]
}
