import SwiftUI
import SwiftUISugar
import SwiftHaptics

extension DensityForm {
    
    var fieldSection: some View {
        @ViewBuilder
        var footer: some View {
            Text("e.g. 1 × cup = 220 g")
        }
        
        return FormStyledSection(
            footer: footer,
            horizontalPadding: 0,
            verticalOuterPadding: 0
        ) {
            field
        }
    }
    
    var field: some View {
        fieldContents
            .frame(height: 50)
    }
    
    var fieldContents: some View {

        var equalsSymbol: some View {
            symbol("=")
                .layoutPriority(3)
        }

        var weightButton: some View {
            button(
                viewModel.weightDescription,
                placeholder: "weight",
                colorScheme: colorScheme
            ) {
                Haptics.feedback(style: .soft)
                showingWeightForm = true
            }
            .layoutPriority(1)
        }

        var volumeButton: some View {
            button(
                viewModel.volumeDescription,
                placeholder: "volume",
                colorScheme: colorScheme
            ) {
                Haptics.feedback(style: .soft)
                showingVolumeForm = true
            }
            .layoutPriority(1)
        }
        
        @ViewBuilder
        var firstButton: some View {
            if fields.isWeightBased {
                weightButton
            } else {
                volumeButton
            }
        }

        @ViewBuilder
        var secondButton: some View {
            if fields.isWeightBased {
                volumeButton
            } else {
                weightButton
            }
        }

        return HStack {
            Group {
                Spacer()
                firstButton
                Spacer()
                equalsSymbol
                Spacer()
                secondButton
                Spacer()
            }
        }
    }
}
