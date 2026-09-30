import SwiftUI
import UIKit

/// Port of AvatarView.java: the "casual" base with outfit layers stacked on top.
struct AvatarView: View {
    let layers: [String]

    // Same stacking order as the Java StackPane.
    private static let layerOrder = ["hot", "coat", "boots", "sunglasses", "Jacket"]

    var body: some View {
        ZStack {
            layer("casual")
            // Layers without a PNG yet (boots, winter coat, sunscreen...) are skipped
            // instead of crashing like the Java version did on snow.
            ForEach(Self.layerOrder.filter { layers.contains($0) && UIImage(named: $0) != nil }, id: \.self) {
                layer($0)
            }
        }
        .frame(width: 150, height: 220)
    }

    private func layer(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none) // keep the pixel art crisp
            .frame(width: 150, height: 220)
    }
}

#Preview {
    AvatarView(layers: ["coat", "Jacket"])
}
