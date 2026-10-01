import SwiftUI
import UIKit

/// Shows the user's own pixelated photo if they've set one (see `AvatarPhotoPickerView`),
/// otherwise a generic pixel-art silhouette. The photo itself is the whole outfit now — there's
/// no clothing-layer overlay system anymore, since whatever the person is wearing in their photo
/// is what the avatar wears.
struct AvatarView: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none) // keep the pixel art crisp
                    .scaledToFit()
            } else {
                Image("casual")
                    .resizable()
                    .interpolation(.none)
            }
        }
        .frame(width: 150, height: 220)
    }
}

#Preview {
    AvatarView(image: nil)
}
