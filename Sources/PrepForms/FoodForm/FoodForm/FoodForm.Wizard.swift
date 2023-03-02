import SwiftUI
import SwiftUISugar

extension FoodForm {
    enum WizardButton {
        case background
        case startWithEmptyFood
        case camera
        case choosePhotos
        case dismiss
    }
    
    struct Wizard: View {
        @Environment(\.colorScheme) var colorScheme
        @Binding var isPresented: Bool
        var tapHandler: ((WizardButton) -> Void)
    }
}

struct DiarySeparatorLineColor {
    static var light = "B3B3B6"
    static var dark = "424242"
}

struct DiaryDividerLineColor {
    static var light = "D6D6D7"
    static var dark = "3a3a3a"  //"333333"
}

extension FoodForm.Wizard {
    
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
                    tapHandler(.startWithEmptyFood)
                } label: {
                    Label("Empty Food", systemImage: "square.and.pencil")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        var scanSection: some View {
            var title: some View {
                Text("Scan a Food Label")
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.footnote)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
            
            var buttons: some View {
                HStack {
                    Button {
                        tapHandler(.camera)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: "camera")
                                .imageScale(.large)
                                .fontWeight(.medium)
                            Text("Camera")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .foregroundStyle(Color.accentColor.gradient)
                            //                                    .foregroundColor(Color.accentColor)
                        )
                    }
                    Button {
                        tapHandler(.choosePhotos)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: "photo.on.rectangle")
                                .imageScale(.large)
                                .fontWeight(.medium)
                            Text("Choose")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .foregroundStyle(Color.accentColor.gradient)
                            //                                    .foregroundColor(Color.accentColor)
                        )
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 5)
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
                buttons
                footer
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
