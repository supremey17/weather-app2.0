import SwiftUI

struct SettingsView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var units: Units = .imperial
    @State private var homeCity = ""
    @State private var adviceEnabled = true
    @State private var avatarEnabled = true
    @State private var accessoriesEnabled = false
    @State private var accessoryDraftIDs: [AccessorySlot: String] = [:]
    @State private var backgroundDraft: PixelBackground = .weather

    /// Mirrors `WeatherViewModel.activeAccessories`'s logic but reads from the local, not-yet-saved
    /// draft state, so the preview reflects in-progress edits before "Save" is tapped.
    private var previewAccessories: [AvatarAccessory] {
        guard accessoriesEnabled, model.avatarEnabled else { return [] }
        return AccessorySlot.allCases.compactMap { slot in
            guard let id = accessoryDraftIDs[slot],
                  let accessory = AvatarAccessory.accessory(id: id),
                  accessory.slot == slot else {
                return nil
            }
            return accessory
        }
    }

    /// Both gates the live preview and dims/disables the per-slot rows: there's nothing useful to
    /// configure if accessories are off, or nothing to show them on if the avatar itself is off.
    private var accessoryControlsDisabled: Bool {
        !accessoriesEnabled || !model.avatarEnabled
    }

    var body: some View {
        NavigationStack {
            ZStack {
                model.weatherTheme.skyColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Home checkpoint", symbol: "house", theme: model.weatherTheme)
                                PixelPanel(theme: model.weatherTheme, style: .hud, padding: 8) {
                                    TextField("e.g. Rochester", text: $homeCity)
                                        .textFieldStyle(.plain)
                                        .pixelFont(.body)
                                        .foregroundStyle(model.weatherTheme.textColor(on: .hud))
                                        .accessibilityLabel("Home city")
                                }
                            }
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Weather units", symbol: "thermometer", theme: model.weatherTheme)
                                HStack(spacing: 10) {
                                    ForEach(Units.allCases) { unit in
                                        Button(unit.label) {
                                            units = unit
                                        }
                                        .buttonStyle(PixelButtonStyle(theme: model.weatherTheme, kind: units == unit ? .primary : .secondary))
                                    }
                                }
                            }
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Dashboard options", symbol: "slider.horizontal.3", theme: model.weatherTheme)
                                Toggle("Gear check", isOn: $adviceEnabled)
                                    .toggleStyle(PixelToggleStyle(theme: model.weatherTheme))
                                Toggle("Avatar", isOn: $avatarEnabled)
                                    .toggleStyle(PixelToggleStyle(theme: model.weatherTheme))
                            }
                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Accessories", symbol: "face.smiling", theme: model.weatherTheme)
                                Toggle("Accessories", isOn: $accessoriesEnabled)
                                    .toggleStyle(PixelToggleStyle(theme: model.weatherTheme))

                                HStack {
                                    Spacer()
                                    AvatarView(
                                        image: model.avatarImage,
                                        size: CGSize(width: 90, height: 130),
                                        accessories: previewAccessories,
                                        anchors: model.avatarFaceAnchors
                                    )
                                    Spacer()
                                }

                                VStack(spacing: 10) {
                                    ForEach(AccessorySlot.allCases, id: \.self) { slot in
                                        AccessorySlotRow(
                                            slot: slot,
                                            selection: $accessoryDraftIDs,
                                            theme: model.weatherTheme,
                                            enabled: !accessoryControlsDisabled
                                        )
                                    }
                                }

                                if !model.avatarEnabled {
                                    Text("Enable Avatar above to use accessories")
                                        .pixelFont(.caption)
                                        .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                                }
                            }
                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Backdrop", symbol: "map", theme: model.weatherTheme)
                                BackdropRow(background: $backgroundDraft, theme: model.weatherTheme)
                            }
                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveSettings(
                                defaultUnits: units,
                                homeCity: homeCity,
                                adviceEnabled: adviceEnabled,
                                avatarEnabled: avatarEnabled,
                                accessoriesEnabled: accessoriesEnabled,
                                accessoryIDs: accessoryDraftIDs,
                                background: backgroundDraft
                            )
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                units = model.defaultUnits
                homeCity = model.homeCity
                adviceEnabled = model.adviceEnabled
                avatarEnabled = model.avatarEnabled
                accessoriesEnabled = model.accessoriesEnabled
                accessoryDraftIDs = model.selectedAccessoryIDs
                backgroundDraft = model.selectedBackground
            }
        }
    }
}

private struct SettingsSectionTitle: View {
    let title: String
    let symbol: String
    let theme: PixelWeatherTheme

    var body: some View {
        HStack(spacing: 6) {
            PixelSprite(PixelSpriteKind(sfSymbol: symbol), scale: 2, tint: theme.accentColor)
            Text(title)
                .pixelFont(.headline)
        }
        .foregroundStyle(theme.textColor(on: .wood))
    }
}

/// Renders a Toggle as a bevel-framed ON/OFF pixel switch with a square thumb that
/// slides to the left (off) or right (on) side of the track.
private struct PixelToggleStyle: ToggleStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .pixelFont(.body)
                .foregroundStyle(theme.textColor(on: .wood))
            Spacer()
            Button {
                configuration.isOn.toggle()
            } label: {
                PixelBevelShape(notch: 3)
                    .fill(theme.palette.panelShade)
                    .frame(width: 64, height: 28)
                    .overlay {
                        PixelBevelShape(notch: 3)
                            .stroke(theme.accentColor.opacity(0.7), lineWidth: 1)
                    }
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Text(configuration.isOn ? "ON" : "OFF")
                            .pixelFont(.caption)
                            .foregroundStyle(theme.panelColor)
                            .frame(width: 32, height: 22)
                            .background(theme.accentColor)
                            .clipShape(PixelBevelShape(notch: 2))
                            .padding(3)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(configuration.isOn ? "On" : "Off")
        }
    }
}

/// One slot's row in the "Accessories" panel: a ◀/▶ pair that cycles through
/// `AvatarAccessory.options(for:)` plus "NONE", via `AvatarAccessory.cycledAccessoryID`.
/// Exposes itself to VoiceOver as a single adjustable element (per Apple's documented pattern for
/// `accessibilityAdjustableAction`) rather than three separately-focusable controls.
private struct AccessorySlotRow: View {
    let slot: AccessorySlot
    @Binding var selection: [AccessorySlot: String]
    let theme: PixelWeatherTheme
    let enabled: Bool

    private var slotName: String {
        switch slot {
        case .head: "Hat"
        case .eyes: "Glasses"
        case .mouth: "Mouth"
        }
    }

    private var currentID: String? { selection[slot] }

    /// A readable name for the current selection — "NONE" when nothing is selected, otherwise
    /// the id capitalized (e.g. "partyhat" -> "Partyhat").
    private var currentName: String {
        currentID?.capitalized ?? "NONE"
    }

    private func step(forward: Bool) {
        let next = AvatarAccessory.cycledAccessoryID(currentID: currentID, slot: slot, forward: forward)
        if let next {
            selection[slot] = next
        } else {
            selection.removeValue(forKey: slot)
        }
    }

    var body: some View {
        HStack {
            Text(slotName)
                .pixelFont(.body)
                .foregroundStyle(theme.textColor(on: .wood))
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                Button("◀") { step(forward: false) }
                    .buttonStyle(PixelButtonStyle(theme: theme, kind: .icon))
                    .disabled(!enabled)

                Text(currentName)
                    .pixelFont(.body)
                    .foregroundStyle(theme.textColor(on: .wood))
                    .frame(minWidth: 90)

                Button("▶") { step(forward: true) }
                    .buttonStyle(PixelButtonStyle(theme: theme, kind: .icon))
                    .disabled(!enabled)
            }
        }
        .opacity(enabled ? 1 : 0.4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(slotName)
        .accessibilityValue(currentName)
        .accessibilityAdjustableAction { direction in
            guard enabled else { return }
            switch direction {
            case .increment: step(forward: true)
            case .decrement: step(forward: false)
            @unknown default: break
            }
        }
    }
}

/// The "Backdrop" panel's single row: a ◀/▶ pair that cycles through `PixelBackground.cycled`.
/// Always enabled — unlike accessories, `.weather` is itself a valid choice, not an "off" state.
/// Exposes itself to VoiceOver as a single adjustable element, mirroring `AccessorySlotRow`.
private struct BackdropRow: View {
    @Binding var background: PixelBackground
    let theme: PixelWeatherTheme

    var body: some View {
        HStack(spacing: 12) {
            Button("◀") { background = PixelBackground.cycled(from: background, forward: false) }
                .buttonStyle(PixelButtonStyle(theme: theme, kind: .icon))

            Text(background.displayName)
                .pixelFont(.body)
                .foregroundStyle(theme.textColor(on: .wood))
                .frame(minWidth: 90)

            Button("▶") { background = PixelBackground.cycled(from: background, forward: true) }
                .buttonStyle(PixelButtonStyle(theme: theme, kind: .icon))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Backdrop")
        .accessibilityValue(background.displayName)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: background = PixelBackground.cycled(from: background, forward: true)
            case .decrement: background = PixelBackground.cycled(from: background, forward: false)
            @unknown default: break
            }
        }
    }
}
