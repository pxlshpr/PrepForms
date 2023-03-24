import SwiftUI
import SwiftUISugar
import SwiftHaptics

extension FoodForm {
    
    var addBarcodeTitle: String {
        "Add a Barcode"
    }
    
    var addBarcodeActions: some View {
        Group {
            TextField("012345678912", text: $barcodePayload)
                .textInputAutocapitalization(.never)
                .keyboardType(.decimalPad)
                .submitLabel(.done)
            Button("Add", action: {
                Haptics.successFeedback()
                withAnimation {
                    handleTypedOutBarcode(barcodePayload)
                }
                barcodePayload = ""
            })
            Button("Cancel", role: .cancel, action: {})
        }
    }
    
    func showAddBarcodeAlert() {
        Haptics.feedback(style: .soft)
        if showingAddBarcodeAlert {
            /// Mitigates glitch where the alert fails to present if we're already presenting a `Menu`, but still sets this flag
            showingAddBarcodeAlert = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingAddBarcodeAlert = true
            }
        } else {
            showingAddBarcodeAlert = true
        }
    }
    
    var addBarcodeMessage: some View {
        Text("Please enter the barcode number for this food.")
    }

    //MARK: - Link Menu
    @ViewBuilder
    var linkMenuActions: some View {
        if let linkInfo = sources.linkInfo {
            Button("View") {
                Haptics.feedback(style: .soft)
                present(.link(linkInfo))
            }
            Button("Remove", role: .destructive) {
                Haptics.successFeedback()
                withAnimation {
                    sources.removeLink()
                }
            }
        }
    }

    @ViewBuilder
    var linkMenuMessage: some View {
        if let linkInfo = sources.linkInfo {
            Text(linkInfo.urlDisplayString)
        }
    }
    
    //MARK: - Barcode Menu
    @ViewBuilder
    var barcodeMenuActions: some View {
        if let barcodeValue = model.lastTappedBarcodeValue {
            Button("Remove", role: .destructive) {
                removeBarcode(barcodeValue)
            }
        }
    }

    @ViewBuilder
    var barcodeMenuMessage: some View {
        if let barcodeValue = model.lastTappedBarcodeValue {
            Text(barcodeValue.string)
        }
    }

    //MARK: - Add Barcode Menu
    @ViewBuilder
    var addBarcodeMenuActions: some View {
        Group {
            Button("Scan") {
                Haptics.feedback(style: .soft)
                presentFullScreen(.barcodeScanner)
            }
            Button("Type in") {
                showAddBarcodeAlert()
            }
        }
    }

    @ViewBuilder
    var addBarcodeMenuMessage: some View {
        Text("Add Barcode")
    }

    func removeBarcode(_ barcodeValue: FieldValue) {
        withAnimation {
            sources.removeBarcodePayload(barcodeValue.string)
            fields.barcodes.removeAll(where: {
                $0.barcodeValue == barcodeValue.barcodeValue
            })
        }
    }

    //MARK: - BarcodesSection
    
    var barcodesSection: some View {
        var header: some View {
            Text("Barcodes")
        }
        
        var footer: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text("This will allow you to scan and log this food.")
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
            }
            .font(.footnote)
        }
        
        let showingBarcodeScannerBinding = Binding<Bool>(
            get: { presentedFullScreenSheet == .barcodeScanner },
            set: { newValue in
                if newValue {
                    presentFullScreen(.barcodeScanner)
                } else {
                    presentedFullScreenSheet = nil
                }
            }
        )
        
        var barcodesForm: some View {
            BarcodesForm(
                barcodeValues: Binding<[FieldValue]>(
                    get: { fields.barcodes.map { $0.value } },
                    set: { _ in }
                ),
                shouldShowFillIcon: Binding<Bool>(
                    get: { fields.hasNonUserInputFills },
                    set: { _ in }
                ),
                showingAddBarcodeAlert: $showingAddBarcodeAlert,
                showingBarcodeScanner: showingBarcodeScannerBinding,
                deleteBarcodes: deleteBarcodes)
        }
        
        var barcodesView: some View {
            BarcodesView(
                barcodeValues: Binding<[FieldValue]>(
                    get: { fields.barcodes.map { $0.value } },
                    set: { _ in }
                ),
                showAsSquares: Binding<Bool>(
                    get: { fields.hasSquareBarcodes },
                    set: { _ in }
                )
            )
        }

        var barcodeValues: [FieldValue] {
            fields.barcodes.map { $0.value }
        }
        
        var buttonWidth: CGFloat {
            (UIScreen.main.bounds.width - (2 * 35.0) - (8.0 * 2.0)) / 3.0
        }
        
        var axes: Axis.Set {
            let shouldScroll = barcodeValues.count > 2
            return shouldScroll ? .horizontal : []
        }

        var emptyContent: some View {
            Group {
                foodFormButton("Scan", image: "barcode.viewfinder", isSecondary: true, colorScheme: colorScheme) {
                    Haptics.feedback(style: .soft)
                    presentFullScreen(.barcodeScanner)
                }
                foodFormButton("Type in", image: "keyboard", isSecondary: true, colorScheme: colorScheme) {
                    showAddBarcodeAlert()
                }
            }
            .frame(width: buttonWidth)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .scale)
            )
        }
        
        var filledAddMenuButton: some View {
            var label: some View {
                foodFormButton("Add", image: "plus", isSecondary: true, colorScheme: colorScheme)
                    .frame(width: buttonWidth)
            }
            
            var menu: some View {
                Menu {
                    Button {
                        Haptics.feedback(style: .soft)
                        presentFullScreen(.barcodeScanner)
                    } label: {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                    
                    Button {
                        showAddBarcodeAlert()
                    } label: {
                        Label("Enter", systemImage: "keyboard")
                    }
                    
                } label: {
                    label
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
            
            var button: some View {
                Button {
                    showingAddBarcodeMenu = true
                } label: {
                    label
                }
            }
            
            return menu
//            return button
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .scale
                ))
        }
        
        func cell(for barcodeValue: FieldValue, image: UIImage) -> some View {
            
            var imageView: some View {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: buttonWidth)
            }
            
            var removeButton: some View {
                Button(role: .destructive) {
                    removeBarcode(barcodeValue)
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
            }
            
            var menu: some View {
                Menu {
                    Text(barcodeValue.string)
                    Divider()
                    removeButton
                } label: {
                    imageView
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
            
            var button: some View {
                Button {
                    model.lastTappedBarcodeValue = barcodeValue
                    showingBarcodeMenu = true
                } label: {
                    imageView
                }
            }
            
            return menu
//            return button
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .scale
                    )
                )
        }
        
        var content: some View {
            FormStyledSection(header: header, footer: footer, horizontalPadding: 0, verticalPadding: 0) {
                ScrollView(axes, showsIndicators: false) {
                    HStack(spacing: 8.0) {
                        ForEach(barcodeValues, id: \.self) { barcodeValue in
                            if let image = barcodeValue.barcodeThumbnail(width: buttonWidth, height: 80) {
                                cell(for: barcodeValue, image: image)
                            }
                        }
                        
                        if barcodeValues.isEmpty {
                            emptyContent
                        }
                        
                        /// Add Menu
                        if !barcodeValues.isEmpty {
                            filledAddMenuButton
                        }

                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                }
                .frame(height: 100)
            }
        }
        
        return content
    }
}
