import SwiftUI
import SwiftUISugar

extension TDEEForm {
    var form: some View {
        FormStyledScrollView {
            if viewModel.isEditing {
                editContents
            } else {
                viewContents
            }
        }
        .safeAreaInset(edge: .bottom) { safeAreaInset }
    }
    
    @ViewBuilder
    var safeAreaInset: some View {
        if showingSaveButton {
            //TODO: Programmatically get this inset (67516AA6)
            Spacer()
                .frame(height: 100)
        }
    }

    @ViewBuilder
    var buttonLayer: some View {
        if showingSaveButton {
            VStack {
                Spacer()
                saveButton
            }
            .transition(.move(edge: .bottom))
        }
    }

    var saveButton: some View {
        var saveButton: some View {
            FormPrimaryButton(title: "Save") {
                didTapSave(viewModel.bodyProfile)
                dismiss()
            }
        }
        
        return VStack(spacing: 0) {
            Divider()
            VStack {
                saveButton
                    .padding(.vertical)
            }
            /// ** REMOVE THIS HARDCODED VALUE for the safe area bottom inset **
//            .padding(.bottom, 30)
        }
        .background(.thinMaterial)
    }
    
    var viewContents: some View {
        Group {
            promptSection
            if viewModel.shouldShowSummary {
                arrowSection
                summarySection
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                if viewModel.isDynamic {
                    HStack(alignment: .firstTextBaseline) {
//                        appleHealthSymbol
                        appleHealthBolt
                            .font(.caption2)
                        Text("These components will be continuously updated as new data comes in from the Health App.")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 17)
                }
            }
        }
    }
    
    var editContents: some View {
        Group {
            maintenanceSection
            Text("=")
                .matchedGeometryEffect(id: "equals", in: namespace)
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            restingEnergySection
            Text("+")
                .matchedGeometryEffect(id: "plus", in: namespace)
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            activeEnergySection
//            restingHealthSection
        }
    }
}
