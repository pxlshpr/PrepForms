//import SwiftUI
//import SwiftUIPager
//import ZoomableScrollView
//
//extension TextPicker {
//
//    //MARK: - Layers
//
//    var pagerLayer: some View {
//        Pager(
//            page: textPickerModel.page,
//            data: textPickerModel.imageModels,
//            id: \.hashValue,
//            content: { imageModel in
//                zoomableScrollView(for: imageModel)
//                    .background(.black)
//            })
//        .sensitivity(.high)
//        .pagingPriority(.high)
//        .onPageWillChange { index in
//            textPickerModel.pageWillChange(to: index)
//        }
//        .onPageChanged { index in
//            textPickerModel.pageDidChange(to: index)
//        }
//        .edgesIgnoringSafeArea(.all)
//    }
//
//
//    var buttonsLayer: some View {
//        VStack(spacing: 0) {
//            topBar
//            Spacer()
//            if textPickerModel.shouldShowBottomBar {
//                bottomBar
//                //TODO: Bring this back after figuring out what's causing the EXC_BAD_ACCESS (code=1) crash
//                //                    .transition(.move(edge: .bottom))
//            }
//        }
//    }
//
//    func titleView(for title: String) -> some View {
//        Text(title)
//            .font(.title3)
//            .bold()
//        //            .padding(12)
//            .padding(.horizontal, 12)
//            .frame(height: 45)
//            .background(
//                RoundedRectangle(cornerRadius: 15)
//                    .foregroundColor(.clear)
//                    .background(.ultraThinMaterial)
//            )
//            .clipShape(
//                RoundedRectangle(cornerRadius: 15)
//            )
//            .shadow(radius: 3, x: 0, y: 3)
//            .padding(.horizontal, 5)
//            .padding(.vertical, 10)
//    }
//
//    func thumbnail(at index: Int) -> some View {
//        var isSelected: Bool {
//            textPickerModel.currentIndex == index
//        }
//
//        return Group {
//            if let image = textPickerModel.imageModels[index].image {
//                Button {
//                    textPickerModel.didTapThumbnail(at: index)
//                } label: {
//                    Image(uiImage: image)
//                        .interpolation(.none)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 55, height: 55)
//                        .clipShape(
//                            RoundedRectangle(cornerRadius: 5, style: .continuous)
//                        )
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 5)
//                                .foregroundColor(.accentColor.opacity(0.2))
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 5)
//                                    //                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3]))
//                                        .strokeBorder(style: StrokeStyle(lineWidth: 2))
//                                        .foregroundColor(.accentColor)
//                                    //                                        .padding(-0.5)
//                                )
//                                .opacity(isSelected ? 1.0 : 0.0)
//                        )
//                }
//            }
//        }
//    }
//}
//
//extension TextPicker {
//
//    func index(of imageModel: ImageModel) -> Int? {
//        guard let index = textPickerModel.imageModels.firstIndex(of: imageModel),
//              index < textPickerModel.zoomBoxes.count
//        else { return nil }
//        return index
//    }
//
//    func id(for imageModel: ImageModel) -> UUID? {
//        guard let index = index(of: imageModel) else { return nil }
//        return textPickerModel.imageModels[index].id
//    }
//
//    func zoomBoxBinding(for imageModel: ImageModel) -> Binding<ZBox?>? {
//        guard let index = index(of: imageModel) else { return nil }
//        return Binding<ZBox?>(
//            get: { textPickerModel.zoomBoxes[index] },
//            set: { _ in }
//        )
//    }
//
//    var showingBoxesBinding: Binding<Bool> {
//        Binding<Bool>(
//            get: { textPickerModel.showingBoxes },
//            set: { _ in }
//        )
//    }
//
//    var textPickerHasAppearedBinding: Binding<Bool> {
//        Binding<Bool>(
//            get: { textPickerModel.hasAppeared },
//            set: { _ in }
//        )
//    }
//
//    @ViewBuilder
//    func zoomableScrollView_new(for imageModel: ImageModel) -> some View {
//        if let id = id(for: imageModel),
//           let zoomBoxBinding = zoomBoxBinding(for: imageModel),
//           let image = imageModel.image
//        {
//            ImageViewer(
//                id: id,
//                image: image,
//                textBoxes: .constant(textPickerModel.textBoxes(for: imageModel)),
//                zoomBox: zoomBoxBinding,
//                showingBoxes: showingBoxesBinding,
//                textPickerHasAppeared: textPickerHasAppearedBinding
//            )
//        }
//    }
//}
//
////MARK: - Legacy
//
//extension TextPicker {
//
//    @ViewBuilder
//    func zoomableScrollView(for imageModel: ImageModel) -> some View {
//        if let index = textPickerModel.imageModels.firstIndex(of: imageModel),
//           index < textPickerModel.zoomBoxes.count,
//           let image = imageModel.image
//        {
//            ZoomableScrollView {
////            ZoomableScrollView(
////                id: textPickerModel.imageModels[index].id,
////                zoomBox: $textPickerModel.zoomBoxes[index],
////                backgroundColor: .black
////            ) {
//                imageView(image)
//                    .overlay(textBoxesLayer(for: imageModel))
//            }
//        }
//    }
//
//    func textBoxesLayer(for imageModel: ImageModel) -> some View {
//        let binding = Binding<[TextBox]>(
//            get: { textPickerModel.textBoxes(for: imageModel) },
//            set: { _ in }
//        )
//        return TextBoxesLayer(textBoxes: binding)
//            .opacity((textPickerModel.hasAppeared && textPickerModel.showingBoxes) ? 1 : 0)
//            .animation(.default, value: textPickerModel.hasAppeared)
//            .animation(.default, value: textPickerModel.showingBoxes)
//    }
//
//    @ViewBuilder
//    func imageView(_ image: UIImage) -> some View {
//        Image(uiImage: image)
//            .resizable()
//            .scaledToFit()
//            .background(.black)
//            .opacity(textPickerModel.showingBoxes ? 0.7 : 1)
//            .animation(.default, value: textPickerModel.showingBoxes)
//    }
//}
