import PhotosUI
import SwiftUI

/// Lets the user pick a photo of themselves to use as their avatar. `PhotosPicker` runs the
/// system's own out-of-process photo UI, so this needs no photo-library permission string.
///
/// The pose check (arms at sides, facing the camera) is a suggestion only — see `PoseGuidance`.
/// Nothing here ever leaves the phone: no network call, no analytics, no logging of the image.
struct AvatarPhotoPickerView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var poseSuggestion: String?
    @State private var isCheckingPose = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                preview

                PhotosPicker("Choose Photo", selection: $pickerItem, matching: .images)
                    .buttonStyle(.bordered)

                if isCheckingPose {
                    ProgressView("Checking pose…")
                } else if let poseSuggestion {
                    Text(poseSuggestion)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                if let previewImage {
                    Button("Use This Photo") {
                        model.setAvatarPhoto(previewImage)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if model.hasAvatarPhoto {
                    Button("Remove Photo", role: .destructive) {
                        model.removeAvatarPhoto()
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("Avatar Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await loadAndCheck(newItem) }
            }
        }
    }

    private var preview: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .accessibilityLabel("Selected photo preview")
            } else {
                ContentUnavailableView(
                    "No Photo Selected",
                    systemImage: "photo",
                    description: Text("A photo of yourself, facing the camera with your arms at your sides, works best — but any photo is fine.")
                )
            }
        }
    }

    private func loadAndCheck(_ item: PhotosPickerItem?) async {
        poseSuggestion = nil
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        previewImage = image

        guard let cgImage = image.cgImage else { return }
        isCheckingPose = true
        let landmarks = await Task.detached(priority: .userInitiated) {
            BodyPoseDetector.detectLandmarks(in: cgImage)
        }.value
        poseSuggestion = landmarks.flatMap(PoseGuidance.evaluate)
        isCheckingPose = false
    }
}
