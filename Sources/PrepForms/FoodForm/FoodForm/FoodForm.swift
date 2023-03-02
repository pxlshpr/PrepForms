import SwiftUI
import SwiftUISugar
import FoodLabelScanner
import PhotosUI
import MFPScraper
import PrepDataTypes
import SwiftHaptics
//import FoodLabelExtractor

public struct FoodForm: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let didSave: (FoodFormOutput) -> ()
    
    @State var showingCancelConfirmation = false
    
    @StateObject var fields: Fields = Fields.shared
    @StateObject var sources: Sources = Sources.shared
    @StateObject var extractor: Extractor = Extractor.shared
    @StateObject var viewModel: ViewModel = ViewModel.shared
    
    @State var showingEmojiPicker = false
    @State var showingDetailsForm = false
    @State var showingPhotosPicker = false
    @State var showingBarcodeScanner = false
    @State var showingSaveSheet = false
    @State var showingSaveButtons = false
    @State var showingAddLinkAlert = false
    @State var showingAddBarcodeAlert = false
    @State var showingDismissConfirmationDialog = false

    let existingFood: Food?
    @State var didPrefillFoodFields = false
    @State var didPrefillFoodSources = false
    @State var selectedPhoto: UIImage? = nil
    @State var barcodePayload: String = ""
    @State var refreshBool = false
    
    let didDismissExtractor = NotificationCenter.default.publisher(for: .didDismissExtractor)
    let didExtractFoodLabel = NotificationCenter.default.publisher(for: .didExtractFoodLabel)
    let shouldDismissFoodForm = NotificationCenter.default.publisher(for: .shouldDismissFoodForm)

    public init(
        existingFood: Food? = nil,
        didSave: @escaping (FoodFormOutput) -> ()
    ) {
        cprint("💭 FoodForm.init()")
        self.didSave = didSave
        self.existingFood = existingFood
    }
    
    public var body: some View {
        content
            .onReceive(didDismissExtractor, perform: didDismissExtractor)
            .onReceive(didExtractFoodLabel, perform: didExtractFoodLabel)
            .onReceive(shouldDismissFoodForm, perform: shouldDismissFoodForm)
    }
    
    var content: some View {
        ZStack {
            navigationView
            wizardLayer
            extractorViewLayer
                .zIndex(2)
            saveSheet
                .zIndex(3)
        }
    }

    var navigationView: some View {
        var formContent: some View {
            ZStack {
                formLayer
                saveButtonLayer
                    .zIndex(3)
                loadingLayer
                    .zIndex(4)
            }
        }
        
        return NavigationStack {
            formContent
                .navigationTitle("\(existingFood == nil ? "New" : "Edit") Food")
                .toolbar { navigationLeadingContent }
                .toolbar { navigationTrailingContent }
                .onAppear(perform: appeared)
                .onChange(of: sources.selectedPhotos, perform: selectedPhotosChanged)
                .onChange(of: viewModel.showingWizard, perform: showingWizardChanged)
                .onChange(of: showingAddLinkAlert, perform: showingAddLinkAlertChanged)
                .onChange(of: showingAddBarcodeAlert, perform: showingAddBarcodeAlertChanged)
            
                .sheet(isPresented: $showingEmojiPicker) { emojiPicker }
                .sheet(isPresented: $showingDetailsForm) { detailsForm }
                .fullScreenCover(isPresented: $showingBarcodeScanner) { barcodeScanner }
                .alert(addBarcodeTitle,
                       isPresented: $showingAddBarcodeAlert,
                       actions: { addBarcodeActions },
                       message: { addBarcodeMessage })
                .photosPicker(
                    isPresented: $showingPhotosPicker,
                    selection: $sources.selectedPhotos,
                    //                    maxSelectionCount: sources.availableImagesCount,
                    maxSelectionCount: 1,
                    matching: .images
                )
        }
    }
    
    func shouldDismissFoodForm(_ notification: Notification) {
        dismissWithHaptics()
    }
    
    func didDismissExtractor(_ notification: Notification) {
        extractorDidDismiss(nil)
    }
    
    func didExtractFoodLabel(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let extractorOutput = userInfo[Notification.Keys.extractorOutput] as? ExtractorOutput else {
            return
        }
        extractorDidDismiss(extractorOutput)
    }
    
    func showingWizardChanged(_ showingWizard: Bool) {
        setShowingSaveButton()
    }
    
    func showingAddLinkAlertChanged(_ newValue: Bool) {
        setShowingSaveButton()
    }
    
    func showingAddBarcodeAlertChanged(_ newValue: Bool) {
        setShowingSaveButton()
    }
    
    func setShowingSaveButton() {
        /// Animating this doesn't work with the custom interactiveDismissal, so we're using a `.animation` modifier on the save button itself
        self.viewModel.showingSaveButton = !(viewModel.showingWizard || showingAddLinkAlert || showingAddBarcodeAlert)
    }
        
    var saveSheet: some View {
        SaveSheet(
            isPresented: $showingSaveSheet,
            validationMessage: Binding<ValidationMessage?>(
            get: { validationMessage },
//            get: { .missingFields(["Protein"]) },
            set: { _ in }
        ), didTapSavePublic: {
            tappedSavePublic()
        }, didTapSavePrivate: {
            tappedSavePrivate()
        })
        .environmentObject(fields)
        .environmentObject(sources)
    }
    
    @ViewBuilder
    var extractorViewLayer: some View {
        if viewModel.showingExtractorView {
            ExtractorView(extractor: extractor, startedWithCamera: viewModel.startWithCamera)
                .onDisappear {
                    NotificationCenter.default.post(name: .homeButtonsShouldRefresh, object: nil)
                }
        }
    }
    
    func selectedPhotosChanged(to items: [PhotosPickerItem]) {
        //        guard let item = items.first else { return }
        //        presentLabelScanner(forCamera: false)
        //        let _ = ImageViewModel(photosPickerItem: item) { image in
        //                self.selectedPhoto = image
        //        }
        //        sources.selectedPhotos = []
        
        guard let item = items.first else { return }
        showExtractor(with: item)
        sources.selectedPhotos = []
    }
    
    func dismissHandler() {
//        withAnimation {
//            viewModel.animateLabelScannerUp = false
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            viewModel.showingLabelScanner = false
//        }
    }
    
    func imageHandler(_ image: UIImage, scanResult: ScanResult) {
        sources.add(image, with: scanResult)
    }
    
    func scanResultHandler(_ scanResult: ScanResult, column: Int? = nil) {
        Haptics.successFeedback()
        if let column = column {
            extract(column: column, from: [scanResult], shouldOverwrite: true)
        } else {
            extractFieldsOrShowColumnSelectionInfo()
        }
    }
    
    //MARK: - Layers
    @ViewBuilder
    var formLayer: some View {
        FormStyledScrollView(showsIndicators: false, isLazy: false) {
            detailsSection
            servingSection
            foodLabelSection
            sourcesSection
            barcodesSection
            Spacer().frame(height: 60) /// to account for save button
        }
        .id(refreshBool)
        .overlay(overlay)
        .blur(radius: viewModel.showingWizardOverlay ? 5 : 0)
        .disabled(viewModel.formDisabled)
    }
    
    @ViewBuilder
    var loadingLayer: some View {
        if existingFood != nil, !didPrefillFoodSources {
            FormStyledScrollView(showsIndicators: false, isLazy: false) {
                FormStyledSection {
                    Color.clear.frame(height: 100)
                }
                .shimmering(animation: Animation.linear(duration: 0.75).repeatForever(autoreverses: false))
                FormStyledSection {
                    Color.clear.frame(height: 50)
                }
                .shimmering(animation: Animation.linear(duration: 0.75).repeatForever(autoreverses: false))
                FormStyledSection {
                    Color.clear.frame(height: 30)
                }
                .shimmering(animation: Animation.linear(duration: 0.75).repeatForever(autoreverses: false))
                FormStyledSection {
                    Color.clear.frame(height: 40)
                }
                .shimmering(animation: Animation.linear(duration: 0.75).repeatForever(autoreverses: false))
                FormStyledSection {
                    Color.clear.frame(height: 40)
                }
                .shimmering(animation: Animation.linear(duration: 0.75).repeatForever(autoreverses: false))
            }
            .transition(.opacity)
        }
    }
    
    var backgroundColor: Color {
        //        Color(.systemGroupedBackground)
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F2F1F6")
    }
    
    var safeAreaInset: some View {
        Spacer().frame(height: 60)
    }
    
    @ViewBuilder
    var overlay: some View {
        if viewModel.showingWizardOverlay {
            Color(.quaternarySystemFill)
                .opacity(viewModel.showingWizardOverlay ? 0.3 : 0)
        }
    }
    
    @ViewBuilder
    var wizardLayer: some View {
        Wizard(
            isPresented: $viewModel.showingWizard,
            tapHandler: tappedWizardButton
        )
    }
    
    var dismissButtonRow: some View {
        var button: some View {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        Color(.tertiaryLabel),
                        Color(.quaternaryLabel)
                            .opacity(0.5)
                    )
                    .font(.system(size: 30))
            }
            .shadow(color: Color(.label).opacity(0.25), radius: 2, x: 0, y: 2)
        }
        
        return HStack {
            button
            Spacer()
        }
        .padding(.bottom, 30)
        .padding(.horizontal, 20)
    }
    
    var buttonsLayer: some View {
        
        let saveIsDisabled = Binding<Bool>(
            get: { !fields.canBeSaved },
            set: { _ in }
        )
        let saveSecondaryIsDisabled = Binding<Bool>(
            get: { !sources.canBePublished },
            set: { _ in }
        )
        let info = Binding<FormSaveInfo?>(
            get: { formSaveInfo },
            set: { _ in }
        )
        
        var saveTitle: String {
            /// [ ] Do this
            //            if isEditingPublicFood {
            //                return "Resubmit to Public Foods"
            //            } else {
            return "Submit to Public Foods"
            //            }
        }
        
        var saveSecondaryTitle: String {
            /// [ ] Do this
            //            if isEditingPublicFood {
            //                return "Save and Make Private"
            //            } else if isEditingPrivateFood {
            //                return "Save Private Food"
            //            } else {
            //            return "Add as Private Food"
            return "Save as Private Food"
            //            }
        }
        
        /// [ ] Check if form is dirty (if editing), or if new, if there's been substantial data entered
        let cancelAction = FormConfirmableAction(
            shouldConfirm: fields.isDirty,
            confirmationMessage: nil,
            confirmationButtonTitle: nil) {
                Haptics.feedback(style: .soft)
                dismiss()
            }
        
        let saveAction = FormConfirmableAction {
            tappedSavePublic()
        }
        
        let saveSecondaryAction = FormConfirmableAction {
            tappedSavePrivate()
        }
        
        return FormDualSaveLayer(
            saveIsDisabled: saveIsDisabled,
            saveSecondaryIsDisabled: saveSecondaryIsDisabled,
            saveTitle: saveTitle,
            saveSecondaryTitle: saveSecondaryTitle,
            info: info,
            preconfirmationAction: nil,
            cancelAction: cancelAction,
            saveAction: saveAction,
            saveSecondaryAction: saveSecondaryAction,
            deleteAction: nil
        )
    }
    
    func tappedSavePublic() {
        guard let data = foodFormOutput(shouldPublish: true) else {
            return
        }
        didSave(data)
        dismiss()
    }
    
    func tappedSavePrivate() {
        guard let data = foodFormOutput(shouldPublish: false) else {
            return
        }
        didSave(data)
        dismiss()
    }
    
    var saveButtonLayer: some View {
        var fontSize: CGFloat {
            25
//            22
        }
        var size: CGFloat {
            48
//            38
        }
        
        var saveButton: some View {
            var imageName: String {
                "checkmark"
            }
            
            var shouldShowAccentColor: Bool {
                fields.hasMinimumRequiredFields
            }
            
            var foregroundColor: Color {
                shouldShowAccentColor
                ? .white
                : Color(.secondaryLabel)
            }
            
            return Button {
                withAnimation {
                    showingSaveSheet.toggle()
                }
                if showingSaveSheet, !fields.hasMinimumRequiredFields {
                    Haptics.warningFeedback()
                } else {
                    Haptics.feedback(style: .soft)
                }
            } label: {
                Image(systemName: imageName)
//                    .foregroundColor(Color.gray)
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
                                .opacity(shouldShowAccentColor ? 1 : 0)
                        }
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                    )

            }
        }
        
        var padding: CGFloat {
            20
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
                .offset(x: viewModel.showingSaveButton ? 0 : padding + size)
                .animation(.interactiveSpring(), value: viewModel.showingSaveButton)
            }
        }
        
        return layer
    }
    
    var saveSheetLayer: some View {
        saveSheet
    }

    var buttonsLayer_legacy: some View {
        VStack {
            Spacer()
            if !viewModel.showingWizard {
                dismissButtonRow
                    .transition(.move(edge: .bottom))
            }
            if fields.canBeSaved {
                saveButtons
                    .transition(.move(edge: .bottom))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    var saveButtons: some View {
        var publicButton: some View {
            FormPrimaryButton(title: "Submit to Prep Database") {
                guard let data = foodFormOutput(shouldPublish: true) else {
                    return
                }
                didSave(data)
                dismiss()
            }
        }
        
        var privateButton: some View {
            FormSecondaryButton(title: "Add to Private Database") {
                guard let data = foodFormOutput(shouldPublish: false) else {
                    return
                }
                didSave(data)
                dismiss()
            }
        }
        
        return VStack(spacing: 0) {
            Divider()
            VStack {
                if sources.canBePublished {
                    publicButton
                        .padding(.top)
                    privateButton
                } else {
                    privateButton
                        .padding(.vertical)
                }
            }
            /// ** REMOVE THIS HARDCODED VALUE for the safe area bottom inset **
            .padding(.bottom, 30)
        }
        .background(.thinMaterial)
    }
    
    //MARK: - Toolbars
    
    var debugFillButton: some View {
        
        func debugFill() {
            let wordLengths = [4, 5, 6, 7, 8]
            let firstWordLength = wordLengths.randomElement()!
            let secondWordLength = wordLengths.randomElement()!

            let firstWord = String((0..<firstWordLength).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! })
            let secondWord = String((0..<secondWordLength).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! })

            let randomString = "\(firstWord) \(secondWord)"
            
            fields.name = randomString
            fields.energy.value = .energy(.init(double: 100, unit: .kcal))
            fields.protein.value = .macro(.init(macro: .protein, double: 20))
            fields.carb.value = .macro(.init(macro: .carb, double: 20))
            fields.fat.value = .macro(.init(macro: .fat, double: 20))
            withAnimation {
                fields.updateFormState()
            }
            Haptics.feedback(style: .rigid)
        }
        
        return Button {
            debugFill()
        } label: {
            Image(systemName: "rectangle.and.pencil.and.ellipsis")
        }
    }
    var navigationTrailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Group {
//                debugFillButton
                dismissButton
            }
            .blur(radius: viewModel.showingWizardOverlay ? 5 : 0)
        }
    }
    
    var dismissButton: some View {
        var dismissConfirmationActions: some View {
            Button("Close without saving", role: .destructive) {
                Haptics.feedback(style: .soft)
                dismiss()
            }
        }
        
        var dismissConfirmationMessage: some View {
            Text("You have unsaved data. Are you sure?")
        }
        
        return Button {
            if fields.isDirty {
                Haptics.warningFeedback()
                showingCancelConfirmation = true
            } else {
                dismissWithHaptics()
            }
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
        .confirmationDialog(
            "",
            isPresented: $showingCancelConfirmation,
            actions: { dismissConfirmationActions },
            message: { dismissConfirmationMessage }
        )
    }
    
    var navigationLeadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
        }
    }
}

extension FoodForm {
    var statusMessage: String? {
        guard !(viewModel.showingWizard || fields.isInEmptyState) else {
            return nil
        }
        if let missingField = fields.missingRequiredField {
            return "Missing \(missingField)"
        } else {
            if sources.canBePublished {
                return nil
            } else {
                return "Missing source"
            }
        }
    }
    
    func tappedNoSource() {
        
    }
    
    func tappedMissingRequiredFields() {
        
    }
    
    var validationMessage: ValidationMessage? {
//        guard !(showingWizard || fields.isInEmptyState) else {
//            return nil
//        }
//
        if !fields.missingRequiredFields.isEmpty {
            return .missingFields(fields.missingRequiredFields)
        } else if !sources.canBePublished {
            return .needsSource
        }
        return nil
    }
    
    var formSaveInfo: FormSaveInfo? {
        guard !(viewModel.showingWizard || fields.isInEmptyState) else {
            return nil
        }
        
        if fields.missingRequiredFields.count > 1 {
            return FormSaveInfo(
                title: "Missing Fields",
                badge: fields.missingRequiredFields.count,
                tapHandler: tappedMissingRequiredFields)
        } else if fields.missingRequiredFields.count == 1 {
            return FormSaveInfo(
                title: "Missing \(fields.missingRequiredFields.first!)",
                systemImage: "questionmark.circle.fill",
                tapHandler: tappedMissingRequiredFields)
        } else {
            if sources.canBePublished {
                return nil
            } else {
                return FormSaveInfo(
                    title: "No Source",
                    systemImage: "info.circle.fill",
                    tapHandler: tappedNoSource)
            }
        }
    }
    
    
    //    var statusMessageColor: Color {
    //        if fields.canBeSaved {
    //            if sources.canBePublished {
    //                return .green.opacity(0.4)
    //            } else {
    //                return .yellow.opacity(0.5)
    //            }
    //        } else {
    //            return Color(.tertiaryLabel).opacity(0.8)
    //        }
    //    }
}

extension FoodForm.Fields {
    var missingRequiredField: String? {
        if name.isEmpty { return "Name" }
        if amount.value.isEmpty { return "Amount" }
        if energy.value.isEmpty { return "Energy" }
        if carb.value.isEmpty { return "Carbohydrate"}
        if fat.value.isEmpty { return "Total Fats" }
        if protein.value.isEmpty { return "Protein"}
        return nil
    }
    
    var missingRequiredFields: [String] {
        var fields: [String] = []
        if name.isEmpty { fields.append("Name") }
        if amount.value.isEmpty { fields.append("Amount") }
        if energy.value.isEmpty { fields.append("Energy") }
        if carb.value.isEmpty { fields.append("Carbohydrate")}
        if fat.value.isEmpty { fields.append("Total Fats") }
        if protein.value.isEmpty { fields.append("Protein")}
        return fields
    }
    
    
    var isInEmptyState: Bool {
        name.isEmpty && detail.isEmpty && brand.isEmpty
        && serving.value.isEmpty
        && energy.value.isEmpty
        && carb.value.isEmpty
        && fat.value.isEmpty
        && protein.value.isEmpty
        && allSizes.isEmpty
        && allMicronutrientFields.isEmpty
        && prefilledFood == nil
    }
}

extension View {
    public func interactiveDismissDisabled2(_ isDisabled: Bool = true, onAttemptToDismiss: (() -> Void)? = nil) -> some View {
        InteractiveDismissableView(view: self, isDisabled: isDisabled, onAttemptToDismiss: onAttemptToDismiss)
    }
    
    public func interactiveDismissDisabled2(_ isDisabled: Bool = true, attemptToDismiss: Binding<Bool>) -> some View {
        InteractiveDismissableView(view: self, isDisabled: isDisabled) {
            attemptToDismiss.wrappedValue.toggle()
        }
    }
    
}

private struct InteractiveDismissableView<T: View>: UIViewControllerRepresentable {
    let view: T
    let isDisabled: Bool
    let onAttemptToDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIHostingController<T> {
        UIHostingController(rootView: view)
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
        context.coordinator.dismissableView = self
        uiViewController.rootView = view
        uiViewController.parent?.presentationController?.delegate = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var dismissableView: InteractiveDismissableView
        
        init(_ dismissableView: InteractiveDismissableView) {
            self.dismissableView = dismissableView
        }
        
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !dismissableView.isDisabled
        }
        
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            dismissableView.onAttemptToDismiss?()
        }
    }
}

struct DismissGuardian<Content: View>: UIViewControllerRepresentable {
    @Binding var preventDismissal: Bool
    @Binding var attempted: Bool
    var contentView: Content
    
    init(preventDismissal: Binding<Bool>, attempted: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.contentView = content()
        self._preventDismissal = preventDismissal
        self._attempted = attempted
    }
        
    func makeUIViewController(context: UIViewControllerRepresentableContext<DismissGuardian>) -> UIViewController {
        return DismissGuardianUIHostingController(rootView: contentView, preventDismissal: preventDismissal)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<DismissGuardian>) {
        (uiViewController as! DismissGuardianUIHostingController).rootView = contentView
        (uiViewController as! DismissGuardianUIHostingController<Content>).preventDismissal = preventDismissal
        (uiViewController as! DismissGuardianUIHostingController<Content>).dismissGuardianDelegate = context.coordinator
    }
    
    func makeCoordinator() -> DismissGuardian<Content>.Coordinator {
        return Coordinator(attempted: $attempted)
    }
    
    class Coordinator: NSObject, DismissGuardianDelegate {
        @Binding var attempted: Bool
        
        init(attempted: Binding<Bool>) {
            self._attempted = attempted
        }
        
        func attemptedUpdate(flag: Bool) {
            self.attempted = flag
        }
    }
}

protocol DismissGuardianDelegate {
    func attemptedUpdate(flag: Bool)
}

class DismissGuardianUIHostingController<Content> : UIHostingController<Content>, UIAdaptivePresentationControllerDelegate where Content : View {
    var preventDismissal: Bool
    var dismissGuardianDelegate: DismissGuardianDelegate?

    init(rootView: Content, preventDismissal: Bool) {
        self.preventDismissal = preventDismissal
        super.init(rootView: rootView)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.presentationController?.delegate = self
        
        self.dismissGuardianDelegate?.attemptedUpdate(flag: false)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        self.dismissGuardianDelegate?.attemptedUpdate(flag: true)
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !self.preventDismissal
    }
}
