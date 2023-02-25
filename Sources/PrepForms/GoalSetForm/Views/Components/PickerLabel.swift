import SwiftUI

struct PickerLabel: View {
    
    let string: String
    let prefix: String?
    let systemImage: String?
    let imageColor: Color
    let imageScale: Image.Scale
    let infiniteMaxHeight: Bool
    
    let backgroundColor: Color
    
    let backgroundGradientTop: Color?
    let backgroundGradientBottom: Color?
    
    let prefixColor: Color
    let foregroundColor: Color
    
    init(
        _ string: String,
        prefix: String? = nil,
        systemImage: String? = "chevron.up.chevron.down",
        imageColor: Color = Color(.tertiaryLabel),
        backgroundColor: Color = Color(.secondarySystemFill),
        backgroundGradientTop: Color? = nil,
        backgroundGradientBottom: Color? = nil,
        foregroundColor: Color = Color(.label),
        prefixColor: Color = Color(.secondaryLabel),
        imageScale: Image.Scale = .small,
        infiniteMaxHeight: Bool = true
    ) {
        self.string = string
        self.prefix = prefix
        self.systemImage = systemImage
        self.imageColor = imageColor
        self.imageScale = imageScale
        self.infiniteMaxHeight = infiniteMaxHeight
        
        self.backgroundGradientTop = backgroundGradientTop
        self.backgroundGradientBottom = backgroundGradientBottom
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.prefixColor = prefixColor
    }
    
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .if(backgroundGradientTop != nil && backgroundGradientBottom != nil, transform: { view in
                    view
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    backgroundGradientTop!,
                                    backgroundGradientBottom!
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                )
                    .if(backgroundGradientTop == nil && backgroundGradientBottom == nil, transform: { view in
                        view
                            .foregroundColor(backgroundColor)
                    })
                    //                .foregroundColor(.white)
                    //                .colorMultiply(backgroundColor)
                    HStack(spacing: 5) {
                    if let prefix {
                        Text(prefix)
                            .foregroundColor(.white)
                            .colorMultiply(prefixColor)
                    }
                    Text(string)
                        .foregroundColor(.white)
                        .colorMultiply(foregroundColor)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundColor(imageColor)
                            .imageScale(imageScale)
                    }
                }
                .frame(height: 25)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
        }
        .fixedSize(horizontal: true, vertical: true)
        .if(infiniteMaxHeight) {
            $0.frame(maxHeight: .infinity)
        }
    }
}

import SwiftUI
import HealthKit
import PrepDataTypes

struct ProfileLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let age: Int
    let sex: HKBiologicalSex
    let weight: Double
    let height: Double?
    let weightUnit: WeightUnit
    let heightUnit: HeightUnit
    
    let isSynced: Bool
    
    init(age: Int, sex: HKBiologicalSex, weight: Double, height: Double? = nil, weightUnit: WeightUnit, heightUnit: HeightUnit, isSynced: Bool) {
        self.age = age
        self.sex = sex
        self.weight = weight
        self.height = height
        self.weightUnit = weightUnit
        self.heightUnit = heightUnit
        self.isSynced = isSynced
    }
    
    var body: some View {
        ZStack {
            background
            HStack {
                pair(age, "yo")
                pair(Int(weight), weightUnit.shortDescription)
                if let height {
                    pair(Int(height), heightUnit.shortDescription)
                }
                Text(sex.description.lowercased())
                    .foregroundColor(primaryColor)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(height: 25)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
    }
    
    var primaryColor: Color {
        isSynced ? .white : .primary
    }
    
    var secondaryColor: Color {
        isSynced ? .white.opacity(0.75) : .secondary
    }
    
    func pair(_ value: Int, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(value)")
                .foregroundColor(primaryColor)
            Text(unit)
                .font(.footnote)
                .foregroundColor(secondaryColor)
        }
    }
    
    var background: some View {
        var color: Color {
            colorScheme == .light ? Color(hex: "e8e9ea") : Color(hex: "434447")
        }
        return Capsule(style: .continuous)
            .if(isSynced, transform: { view in
                view
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color(hex: AppleHealthTopColorHex),
                                Color(hex: AppleHealthBottomColorHex)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            })
                .if(!isSynced, transform: { view in
                    view
                        .foregroundColor(color)
                })
    }
}

struct ProfileLabel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground)
            ProfileLabel(
                age: 35,
                sex: .male,
                weight: 95.6,
                height: 177.04,
                weightUnit: .kg,
                heightUnit: .cm,
                isSynced: false
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}
