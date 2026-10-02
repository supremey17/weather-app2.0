import PhotosUI
import SwiftUI

/// Imports and processes an avatar locally. The selected image is never uploaded.
struct AvatarPhotoPickerView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var poseSuggestion: String?
    @State private var isCheckingPose = false
    @State private var isSavingPhoto = false

    var body: some View {
        NavigationStack {
            ZStack {
                model.weatherTheme.skyColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        PixelPanel(theme: model.weatherTheme) {
                            VStack(spacing: 16) {
                                preview

                                PhotosPicker("Choose Photo", selection: $pickerItem, matching: .images)
                                    .buttonStyle(PixelTextButtonStyle(theme: model.weatherTheme))

                                statusMessage
                            }
                        }

                        if let previewImage {
                            Button("Use This Photo") {
                                Task {
                                    isSavingPhoto = true
                                    await model.setAvatarPhoto(previewImage)
                                    isSavingPhoto = false
                                    dismiss()
                                }
                            }
                            .buttonStyle(PixelTextButtonStyle(theme: model.weatherTheme))
                            .disabled(isSavingPhoto)
                        }

                        if model.hasAvatarPhoto {
                            Button("Remove Photo", role: .destructive) {
                                model.removeAvatarPhoto()
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Avatar Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

    @ViewBuilder
    private var statusMessage: some View {
        if isCheckingPose {
            ProgressView("Checking pose…")
                .tint(model.weatherTheme.accentColor)
        } else if isSavingPhoto {
            ProgressView("Creating your local avatar…")
                .tint(model.weatherTheme.accentColor)
        } else if let poseSuggestion {
            Text(poseSuggestion)
                .font(.footnote)
                .foregroundStyle(model.weatherTheme.panelTextColor.opacity(0.82))
                .multilineTextAlignment(.center)
        } else {
            Text("Your photo stays on this device and is excluded from iCloud backup.")
                .font(.footnote)
                .foregroundStyle(model.weatherTheme.panelTextColor.opacity(0.82))
                .multilineTextAlignment(.center)
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
                    systemImage: "person.crop.rectangle",
                    description: Text("A front-facing photo with your arms at your sides works best, but any photo is fine.")
                )
                .foregroundStyle(model.weatherTheme.panelTextColor)
            }
        }
    }

    private func loadAndCheck(_ item: PhotosPickerItem?) async {
        poseSuggestion = nil
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let rawImage = UIImage(data: data) else { return }
        let image = await Task.detached(priority: .userInitiated) {
            AvatarImageProcessing.normalizingOrientation(rawImage)
        }.value
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
