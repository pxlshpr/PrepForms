import SwiftUI

struct PickerLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
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
//        backgroundColor: Color = Color(.secondarySystemFill),
        backgroundColor: Color = Color(.secondaryLabel),
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
//        legacyContent
        content
            .fixedSize(horizontal: true, vertical: true)
            .if(infiniteMaxHeight) {
                $0.frame(maxHeight: .infinity)
            }
    }
    
    var content: some View {
        var capsuleLayer: some View {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
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
                            .opacity(colorScheme == .dark ? 0.1 : 0.15)
                        )
                })
                .if(backgroundGradientTop == nil && backgroundGradientBottom == nil, transform: { view in
                    view
                        .foregroundColor(
                            backgroundColor
                                .opacity(colorScheme == .dark ? 0.1 : 0.15)
                        )
                })
        }
        
        var contentsLayer: some View {
            HStack(spacing: 5) {
                if let prefix {
                    Text(prefix)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                        .colorMultiply(prefixColor)
                        .foregroundColor(backgroundColor)
                }
                Text(string)
                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                    .colorMultiply(foregroundColor)
                    .foregroundColor(backgroundColor)
                if let systemImage {
                    Image(systemName: systemImage)
//                        .foregroundColor(imageColor)
                        .imageScale(imageScale)
                        .foregroundColor(backgroundColor)
                }
            }
            .frame(height: 25)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        
        return ZStack {
            capsuleLayer
            contentsLayer
        }
    }
    
    var legacyContent: some View {
        
        var capsuleLayer: some View {
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
                })
                .if(backgroundGradientTop == nil && backgroundGradientBottom == nil, transform: { view in
                    view
                        .foregroundColor(backgroundColor)
                })
        }
        
        var contentsLayer: some View {
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
        
        return ZStack {
            capsuleLayer
            contentsLayer
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
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(height: 25)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
    }
    
    var primaryColor: Color {
//        isSynced ? .white : .primary
        isSynced
        ? Color(hex: AppleHealthTopColorHex)
        : Color(.secondaryLabel)
    }
    
    var secondaryColor: Color {
        isSynced ? .white.opacity(0.75) : .secondary
    }
    
    func pair(_ value: Int, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(value)")
                .foregroundColor(primaryColor)
                .fontWeight(.bold)
//                .foregroundColor(Color(hex: AppleHealthTopColorHex))
            Text(unit)
                .font(.footnote)
//                .foregroundColor(secondaryColor)
                .foregroundColor(primaryColor)
        }
    }
    
    var background: some View {
        var color: Color {
            colorScheme == .light ? Color(hex: "e8e9ea") : Color(hex: "434447")
        }
//        return Capsule(style: .continuous)
        return RoundedRectangle(cornerRadius: 7, style: .continuous)
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
                        .opacity(colorScheme == .dark ? 0.1 : 0.15)
                    )
            })
                .if(!isSynced, transform: { view in
                    view
                        .foregroundColor(
                            Color(.secondaryLabel)
//                            color
                                .opacity(colorScheme == .dark ? 0.1 : 0.15)
                        )
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
