import SwiftUI
import SwiftSugar

//MARK: **** Move this to SwiftUISugar ****

/**
 A tag-cloud like flow layout that supports multiple alignments.
 
 If this view is padded horizontally, the padding used needs to provided so that the subviews may be aligned properly.
 
 [ ] Figure out a way to align items properly without requiring the external padding to be provided.
 */
struct FlowView: Layout {
    
    var alignment: Alignment = .center
    var spacing: CGFloat = 10
    var padding: CGFloat = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let boundsSize = CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
        let bounds = CGRect(origin: CGPoint(x: padding, y: 0), size: boundsSize)
        let rects = calculateRects(in: bounds, subviews: subviews)
        let height = rects.last?.maxY ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rects = calculateRects(in: bounds, subviews: subviews)
        rects.enumerated().forEach { index, rect in
            let sizeProposal = ProposedViewSize(rect.size)
            subviews[index].place(at: rect.origin, proposal: sizeProposal)
        }
    }
    
    func calculateRects(in bounds: CGRect, subviews: Subviews) -> [CGRect] {
        var rects: [CGRect] = []
        var nextOrigin = bounds.origin
        let maxWidth = bounds.width
        
        var row: (views: [LayoutSubviews.Element], remainingX: Double) = ([], 0)
        var rows: [(views: [LayoutSubviews.Element], remainingX: Double)] = []
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if (nextOrigin.x + viewSize.width + spacing) > maxWidth {
                /// Create a new row
                row.remainingX = (bounds.maxX - nextOrigin.x + bounds.minX + spacing)
                rows.append(row)
                row.views.removeAll()
                nextOrigin.x = bounds.origin.x
                row.views.append(view)
                nextOrigin.x += (viewSize.width + spacing)
            } else {
                /// Add the view to the current row
                row.views.append(view)
                nextOrigin.x += (viewSize.width + spacing)
            }
        }
        
        if !row.views.isEmpty {
            row.remainingX = (bounds.maxX - nextOrigin.x + bounds.minX + spacing)
            rows.append(row)
        }
        
        nextOrigin = bounds.origin
        for rowIndex in rows.indices {
            let row = rows[rowIndex]
            switch alignment {
            case .trailing:
                nextOrigin.x = row.remainingX
            case .center:
                /// We're setting the offset for center aligned FlowViews based on the padding we've been supplied
                let offset: CGFloat
                if spacing == 0 {
                    offset = (padding / 2.0)
                } else {
                    offset = min(padding, spacing) * (padding / spacing / 2.0)
                }
                nextOrigin.x = ((row.remainingX) / 2.0) + offset
            default:
                nextOrigin.x = bounds.minX
            }
            
            for viewIndex in row.views.indices {
                let view = row.views[viewIndex]
                let viewSize = view.sizeThatFits(.unspecified)
                rects.append(CGRect(origin: nextOrigin, size: viewSize))
                nextOrigin.x += (viewSize.width + spacing)
            }
            
            let maxHeight = row.views.compactMap { view in
                return view.sizeThatFits(.unspecified).height
            }.max() ?? 0
            nextOrigin.y += (maxHeight + spacing)
        }

        return rects
    }
}

public struct FlowViewPreview: View {
    
    @State var padding: CGFloat = 16
    @State var spacing: CGFloat = 0

    public init() { }
    public var body: some View {
        scrollView
    }
    
    var strings: [String] {
        [
            "Hello there hi how are you",
            "Hi what's up",
            "What's your name",
            "Are you good",
        ]
    }
    
    var paddingStepper: some View {
        Stepper("Padding: \(Double(padding).cleanAmount)") {
            padding += 1
        } onDecrement: {
            let newPadding = padding - 1
            padding = max(newPadding, 0)
        }
    }
    
    var spacingStepper: some View {
        Stepper("Spacing: \(Double(spacing).cleanAmount)") {
            spacing += 1
        } onDecrement: {
            let newSpacing = spacing - 1
            spacing = max(newSpacing, 0)
        }
    }
    
    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                FlowView(alignment: .center, spacing: spacing, padding: padding) {
                    ForEach(strings, id: \.self) {
                        PickerLabel($0, infiniteMaxHeight: false)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, padding)
            Spacer().frame(height: 50)
            Group {
                paddingStepper
                spacingStepper
            }
            .frame(width: 200)
        }
        .background(
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all) /// requireds to cover the area that would be covered by the keyboard during its dismissal animation
        )
    }
}

struct FlowView_Previews: PreviewProvider {
    static var previews: some View {
        FlowViewPreview()
    }
}
