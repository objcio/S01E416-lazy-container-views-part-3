//

import SwiftUI

struct LazyVStackLayout: Layout {
    var spacing: CGFloat?

    func spacings(for subviews: Subviews) -> [CGFloat] {
        subviews.indices.dropLast().map { idx in
            spacing ?? subviews[idx].spacing.distance(to: subviews[idx+1].spacing, along: .vertical)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {

        var result: CGSize = .zero
        let spaces = spacings(for: subviews)

        for s in subviews {
            let size = s.sizeThatFits(.init(width: proposal.width, height: nil))
            result.height += size.height
            result.width = max(result.width, size.width)
        }

        result.height += spaces.reduce(0, +)

        return result
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentY: CGFloat = 0
        let spaces = spacings(for: subviews)
        for (offset, s) in subviews.enumerated() {
            var point = bounds.origin
            point.y += currentY
            let prop = ProposedViewSize(width: proposal.width, height: nil)
            let size = s.sizeThatFits(prop)
            s.place(at: point, proposal: prop)
            currentY += size.height
            if offset < subviews.count - 1 {
                currentY += spaces[offset]
            }
        }
    }
}

struct MyLazyVStack<Content: View>: View {
    var spacing: CGFloat? = nil

    @ViewBuilder var content: Content
    @State var numberOfSubviewsVisible = 1
    @State var maxY: CGFloat = 0
    @State var currentHeight: CGFloat = 0

    var body: some View {
        Group(subviews: content) { coll in
            LazyVStackLayout(spacing: spacing) {
                coll.prefix(numberOfSubviewsVisible)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.bounds(of: .scrollView)!.maxY
            } action: { newValue in
                maxY = newValue
            }
            .onGeometryChange(for: CGFloat.self, of: { maxY - $0.size.height }, action: { newValue in
                if newValue > 0 && numberOfSubviewsVisible < coll.count {
                    numberOfSubviewsVisible += 1
                    print(numberOfSubviewsVisible)
                }
            })
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { newValue in
                currentHeight = newValue
            }
            .frame(minHeight: currentHeight / .init(numberOfSubviewsVisible) * .init(coll.count), alignment: .top)
        }
    }
}

struct ContentView: View {
    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                LazyVStack() {
                    Image(systemName: "globe")
                    ForEach(0..<100) { ix in
                        Text("item \(ix)")
                            .border(Color.red)
                            .onAppear { print("onAppear", ix) }
                        Color.blue
                    }
                }
                MyLazyVStack() {
                    Image(systemName: "globe")
                    ForEach(0..<100) { ix in
                        Text("item \(ix)")
                            .border(Color.red)
                            .onAppear { print("onAppear", ix) }
                        Color.blue
                    }
                }
            }


        }
    }
}

#Preview {
    ContentView()
}
