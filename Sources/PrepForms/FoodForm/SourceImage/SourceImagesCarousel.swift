import SwiftUI
import SwiftHaptics

struct SourceImagesCarousel: View {
    
    @Binding var imageModels: [ImageModel]
    
    var didTapViewOnImage: ((Int) -> ())? = nil
    var didTapDeleteOnImage: ((Int) -> ())? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(imageModels.indices, id: \.self) { index in
                    sourceImage(at: index)
                        .padding(.leading, index == 0 ? 10 : 0)
                        .padding(.trailing, index ==  imageModels.count - 1 ? 10 : 0)
                }
            }
        }
        .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
    }
    
    func sourceImage(at index: Int) -> some View {
        Menu {
            Button("View") {
                Haptics.feedback(style: .soft)
                didTapViewOnImage?(index)
            }
            Button(role: .destructive) {
                Haptics.warningFeedback()
                didTapDeleteOnImage?(index)
            } label: {
                Text("Delete")
            }
        } label: {
            SourceImage(imageModel: imageModels[index])
        } primaryAction: {
            Haptics.feedback(style: .soft)
            didTapViewOnImage?(index)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
    }
}
