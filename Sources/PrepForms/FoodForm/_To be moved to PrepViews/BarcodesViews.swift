//TODO: Move this PrepUnits after moving FieldValue (which we should move after cleaning it and changing BarcodeView to not use VN...Symbology—using our custom type instead)
import SwiftUI

struct BarcodesView: View {
    
    @Binding var barcodeValues: [FieldValue]
    @Binding var showAsSquares: Bool
    
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(barcodeValues.indices, id: \.self) {
                barcodeView(for: barcodeValues[$0])
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func barcodeView(for barcodeValue: FieldValue) -> some View {
        if let image = barcodeValue.barcodeThumbnail(asSquare: showAsSquares) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100)
                .shadow(radius: 3, x: 0, y: 3)
                .padding()
        }
    }
}
