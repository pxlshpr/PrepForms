//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//import PrepCoreDataStack
//
//extension EnergyGoalForm {
//    var body: some View {
//        FormStyledScrollView {
//            HStack(spacing: 0) {
//                lowerBoundSection
//                middleSection
//                upperBoundSection
//            }
//            unitSection
//                .padding(.bottom, 10)
//            equivalentSection
//        }
//        .navigationTitle("Energy")
//        .navigationBarTitleDisplayMode(.large)
//        .toolbar { trailingContent }
//        .onChange(of: pickedMealEnergyGoalType, perform: mealEnergyGoalChanged)
//        .onChange(of: pickedDietEnergyGoalType, perform: dietEnergyGoalChanged)
//        .onChange(of: pickedDelta, perform: deltaChanged)
//        .onAppear(perform: appeared)
//        .sheet(isPresented: $showingTDEEForm) { tdeeForm }
//        .onDisappear(perform: disappeared)
//        .scrollDismissesKeyboard(.interactively)
//    }
//    
//    func disappeared() {
//        goal.validateEnergy()
//        model.createImplicitGoals()
//    }
//    
//    var trailingContent: some ToolbarContent {
//        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            syncedIndicator
//            menu
//        }
//    }
//    
//    var menu: some View {
//        Menu {
//            Button(role: .destructive) {
//                Haptics.warningFeedback()
//                didTapDelete(goal)
//            } label: {
//                Label("Remove Goal", systemImage: "minus.circle")
//            }
//        } label: {
//            Image(systemName: "ellipsis")
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
//    }
//    
//    @ViewBuilder
//    var syncedIndicator: some View {
//        if isSynced {
//            appleHealthBolt
//            Text("Synced")
//                .font(.footnote)
//                .textCase(.uppercase)
//                .foregroundColor(Color(.tertiaryLabel))
//        }
//    }
//    
//    var isSynced: Bool {
//        goal.isSynced
//    }
//    
//    @ViewBuilder
//    var unitsFooter: some View {
//        if isSynced {
//            Text("Your maintenance \(UserManager.energyDescription.lowercased()) is synced with the Health App, so this goal will adjust automatically to any changes.")
//        }
//    }
//    
//    var unitSection: some View {
//        var horizontalScrollView: some View {
//            FormStyledSection(footer: unitsFooter, horizontalPadding: 0) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        typePicker
//                        deltaPicker
//                        tdeeButton
//                    }
//                    .padding(.horizontal, 17)
//                }
//                .frame(maxWidth: .infinity)
//            }
//        }
//        
//        var flowView: some View {
//            FormStyledSection {
//                FlowView(alignment: .leading, spacing: 10, padding: 37) {
//                    typePicker
//                    deltaPicker
//                    tdeeButton
//                }
//            }
//        }
//        
//        return Group {
//            horizontalScrollView
////            flowView
//        }
//    }
//    
//    var tdeeForm: some View {
//        TDEEForm()
//    }
//    
//    @ViewBuilder
//    var tdeeButton: some View {
//        if shouldShowEnergyDeltaElements {
//            Button {
//                shouldResignFocus.toggle()
//                Haptics.feedback(style: .soft)
//                showingTDEEForm = true
//            } label: {
//                if let formattedTDEE = UserManager.biometrics.formattedTDEEWithUnit {
//                    if UserManager.biometrics.syncsMaintenanceEnergy {
//                        PickerLabel(
//                            formattedTDEE,
//                            systemImage: "flame.fill",
//                            imageColor: Color(hex: "F3DED7"),
//                            backgroundGradientTop: HealthTopColor,
//                            backgroundGradientBottom: HealthBottomColor,
//                            foregroundColor: .white,
//                            imageScale: .small
//                        )
//                    } else {
//                        PickerLabel(
//                            formattedTDEE,
//                            systemImage: "flame.fill",
//                            imageColor: Color(.tertiaryLabel),
//                            imageScale: .small
//                        )
//                    }
//                } else {
//                    PickerLabel(
//                        "set",
////                        prefix: "set",
//                        systemImage: "flame.fill",
//                        imageColor: Color.white.opacity(0.75),
//                        backgroundColor: .accentColor,
//                        foregroundColor: .white,
//                        prefixColor: Color.white.opacity(0.75),
//                        imageScale: .small
//                    )
//                }
//            }
//        }
//    }
//}
//
//extension EnergyGoalForm {
//    
//    var lowerBoundSection: some View {
//        let binding = Binding<Double?>(
//            get: {
//                return goal.lowerBound
//            },
//            set: { newValue in
//                withAnimation {
//                    goal.lowerBound = newValue
//                }
//            }
//        )
//        
//        var header: some View {
//            Text(goal.haveBothBounds ? "From" : "At least")
//        }
//        return FormStyledSection(header: header) {
//            HStack {
//                DoubleTextField(
//                    double: binding,
//                    placeholder: "Optional",
//                    shouldResignFocus: $shouldResignFocus
//                )
//            }
//        }
//    }
//    
//    var upperBoundSection: some View {
//        let binding = Binding<Double?>(
//            get: { goal.upperBound },
//            set: { newValue in
//                withAnimation {
//                    goal.upperBound = newValue
//                }
//            }
//        )
//
//        var header: some View {
//            Text(goal.haveBothBounds ? "To" : "At most")
//        }
//        return FormStyledSection(header: header) {
//            HStack {
//                DoubleTextField(
//                    double: binding,
//                    placeholder: "Optional",
//                    shouldResignFocus: $shouldResignFocus
//                )
//            }
//        }
//    }
//    
//    var middleSection: some View {
//        VStack(spacing: 7) {
//            Text("")
//            if goal.lowerBound != nil, goal.upperBound == nil {
//                Button {
//                    Haptics.feedback(style: .rigid)
//                    goal.upperBound = goal.lowerBound
//                    goal.lowerBound = nil
//                } label: {
////                    Image(systemName: "arrowshape.right.fill")
//                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
//                        .foregroundColor(.accentColor)
//                }
//            } else if goal.upperBound != nil, goal.lowerBound == nil {
//                Button {
//                    Haptics.feedback(style: .rigid)
//                    goal.lowerBound = goal.upperBound
//                    goal.upperBound = nil
//                } label: {
////                    Image(systemName: "arrowshape.left.fill")
//                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
//                        .foregroundColor(.accentColor)
//                }
//            }
////            else if goal.upperBound != nil, goal.lowerBound != nil {
////                Text("to")
////                    .font(.system(size: 17))
////                    .foregroundColor(Color(.tertiaryLabel))
////            }
//        }
//        .padding(.top, 10)
//        .frame(width: 16, height: 20)
//    }
//    
//    var unitView: some View {
//        HStack {
//            Text(goal.energyGoalType?.description ?? "")
//                .foregroundColor(Color(.tertiaryLabel))
//            if let difference = goal.energyGoalDelta {
//                Spacer()
//                Text(difference.description)
//                    .foregroundColor(Color(.quaternaryLabel))
//            }
//        }
//    }
//    
//    @ViewBuilder
//    var footer: some View {
//        EmptyView()
//    }
//    
//    var equivalentSection: some View {
//        @ViewBuilder
//        var header: some View {
//            if isSynced {
//                Text("Currently Equals")
//            } else {
//                Text("Equals")
//            }
//        }
//        
//        return Group {
//            if goal.haveEquivalentValues {
//                FormStyledSection(header: header) {
//                    goal.equivalentTextHStack
//                }
//            }
//        }
//    }
//}
