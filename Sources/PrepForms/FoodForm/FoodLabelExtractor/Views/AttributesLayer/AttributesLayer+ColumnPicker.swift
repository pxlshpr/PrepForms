import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension AttributesLayer {
    
    var columnPicker: some View {
        VStack {
            Spacer()
            columnPickerInstructions
                .padding(.horizontal)
            Spacer()
            Group {
                segmentedPicker
                autoFillButton
            }
            .padding(.horizontal, K.SegmentedButton.paddingHorizontal)
        }
        .padding(.bottom, K.bottomSafeAreaPadding)
    }
    
    var columnPickerInstructions: some View {
        VStack(spacing: 10) {
            Text("We recommend choosing the column with larger values.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
//            Divider()
//                .frame(width: 200)
            Text("This reduces rounding errors as much as possible.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal)
                .padding(.horizontal)
        }
    }
    
}

extension AttributesLayer {
    var segmentedPicker: some View {
        ZStack {
            background
            button
            texts
        }
        .frame(height: 50)
        .highPriorityGesture(dragGesture)
//        .gesture(dragGesture)
    }
    
    var r: CGFloat { 3 }
    
    var innerTopLeftShadowColor: Color {
        colorScheme == .light
        ? Color(red: 197/255, green: 197/255, blue: 197/255)
        : Color(hex: "232323")
    }

    var innerBottomRightShadowColor: Color {
        colorScheme == .light
        ? Color.white
        : Color(hex: "3D3E44")
    }

    var backgroundColor: Color {
        colorScheme == .light
        ? Color(red: 236/255, green: 234/255, blue: 235/255)
        : Color(hex: "303136")
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(
                .shadow(.inner(color: innerTopLeftShadowColor,radius: r, x: r, y: r))
                .shadow(.inner(color: innerBottomRightShadowColor, radius: r, x: -r, y: -r))
            )
            .foregroundColor(backgroundColor)
    }
    
    var selectedColumn: Int {
        extractor.extractedColumns.selectedColumnIndex
    }
    
    var leftButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            withAnimation(.interactiveSpring()) {
                extractor.selectColumn(1)
            }
        } label: {
            Text(extractor.leftColumnTitle)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(selectedColumn == 1 ? .white : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
    }
    
    var rightButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            withAnimation(.interactiveSpring()) {
                extractor.selectColumn(2)
            }
        } label: {
            Text(extractor.rightColumnTitle)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(selectedColumn == 2 ? .white : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
    }
    
    var autoFillButton: some View {
        Button {
            Task {
                try await extractor.extractNutrients()
            }
        } label: {
            Text("Use this column")
                .font(.system(size: 22, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .foregroundStyle(Color.accentColor.gradient)
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                )
                .contentShape(Rectangle())
        }
    }

    func dragChanged(_ value: DragGesture.Value) {
        var translation = value.translation.width
        if selectedColumn == 1 {
            translation = max(0, translation)
            translation = min(translation, buttonWidth)
        } else {
            translation = max(-buttonWidth, translation)
            translation = min(0, translation)
        }
        self.dragTranslationX = translation
    }
    
    var buttonIsOnRight: Bool {
        buttonXPosition > buttonWidth
    }
    func dragEnded(_ value: DragGesture.Value) {
        var transitionAnimation: Animation {
            .interactiveSpring()
//            .default
        }
        
        var cancelAnimation: Animation {
            .interactiveSpring()
        }
        cprint("👉🏽 drag.translation: \(value.translation)")
        let predictedTranslationX = value.predictedEndTranslation.width
        let predictedButtonX = (buttonWidth / 2.0) + (selectedColumn == 2 ? buttonWidth : 0) + predictedTranslationX
        let predictedButtonIsOnRight = predictedButtonX > buttonWidth
        
        if predictedButtonIsOnRight {
            if selectedColumn == 1 {
                Haptics.feedback(style: .soft)
                cprint("👉🏽 setting dragTranslation as: \(buttonWidth) with animation before resetting to nil")
                withAnimation(transitionAnimation) {
                    dragTranslationX = buttonWidth
                }
                dragTranslationX = nil
                extractor.selectColumn(2)
            } else {
                withAnimation(cancelAnimation) {
                    dragTranslationX = nil
                }
            }
        } else {
            if selectedColumn == 2 {
                Haptics.feedback(style: .soft)
//                dragTranslationX = nil
                cprint("👉🏽 setting dragTranslation as: -\(buttonWidth) with animation before resetting to nil")
                withAnimation(transitionAnimation) {
                    dragTranslationX = -buttonWidth
                }
                dragTranslationX = nil
                extractor.selectColumn(1)
            } else {
                withAnimation(cancelAnimation) {
                    dragTranslationX = nil
                }
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged(dragChanged)
            .onEnded(dragEnded)
    }

    var button: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .foregroundStyle(Color.accentColor.gradient)
            .shadow(color: innerTopLeftShadowColor, radius: 2, x: 0, y: 2)
            .padding(3)
            .frame(width: buttonWidth)
            .position(x: buttonXPosition, y: 25)
            .animation(
                .interactiveSpring(),
                value: extractor.extractedColumns.selectedColumnIndex
            )
//            .gesture(dragGesture)
    }

    var texts: some View {
        HStack(spacing: 0) {
            VStack {
                leftButton
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            VStack {
                rightButton
            }
            .frame(minWidth: 0, maxWidth: .infinity)

        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var buttonWidth: CGFloat {
        (UIScreen.main.bounds.width - (K.SegmentedButton.paddingHorizontal * 2.0)) / 2.0
    }
    
    var buttonXPosition: CGFloat {
        var x = (buttonWidth / 2.0) + (selectedColumn == 2 ? buttonWidth : 0)
        if let dragTranslationX {
            x += dragTranslationX
        }
        x = max(x, (buttonWidth / 2.0))
        x = min(x, (buttonWidth / 2.0) + buttonWidth)
        return x
    }
}
