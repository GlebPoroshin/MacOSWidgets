# LiquidGlass Dash

LiquidGlass Dash is a macOS 15+ dashboard that ships a SwiftUI container app, two WidgetKit extensions, and a background sampler login item. The widgets replicate the "Liquid Glass" visual style and surface live CPU/memory metrics alongside a visual map of connected displays.

## Targets

- **LiquidGlassDash (App)** – SwiftUI host with preview, sampler configuration, and quick links.
- **LiquidGlassDashStatsWidget** – WidgetKit extension rendering CPU/RAM gauges and history sparklines.
- **LiquidGlassDashDisplaysWidget** – WidgetKit extension drawing the current multi-display topology with quick actions.
- **SamplerAgent** – Login item (via `SMAppService`) that samples system statistics and writes snapshots to the shared container.
- **SPM modules** – `CoreStats`, `DisplaysKit`, and `DesignSystem` are delivered via `Package.swift`.

## Data Flow

1. `SamplerAgent` captures system metrics every *N* seconds (configured in-app) using Mach host APIs and Quartz Display Services.
2. Snapshots persist as JSON in the shared app group (`group.com.glebporoshin.liquidglassdash`).
3. Widgets and the app read the latest snapshots through lightweight stores and render updated timelines when the agent pushes data.

## Building

### Requirements

- Xcode 16 beta or newer (Swift 6 toolchain)
- macOS 15 (Sequoia) or macOS 26 (Tahoe preview SDK)

### Steps

1. Open `LiquidGlassDash.xcworkspace`.
2. Select the appropriate scheme (`LiquidGlassDash`, `LiquidGlassDashStatsWidget`, `LiquidGlassDashDisplaysWidget`, or `SamplerAgent`).
3. Ensure the signing team is set for all four targets.
4. Run the `LiquidGlassDash` app once to register the login item through SMAppService.

### App Group & Signing

The default app group identifier is `group.com.glebporoshin.liquidglassdash`. Update this identifier (and matching bundle IDs) if you change the team or domain.

## Sampler Agent

- Runs headless as a login item, sampling CPU/RAM stats and active displays.
- Configure the sample interval (5–60 s) and login-item enablement inside the app.
- Widgets rely on the agent; without it only placeholder data appears.

## Widgets & Intents

- Stats widget families: small, medium, large. Includes AppIntents for clearing history and opening the dashboard.
- Displays widget families: medium, large. AppIntents open System Settings → Displays and provide mirrors/primary guidance (`NON_MAS` builds can integrate [displayplacer](https://github.com/jakehilborn/displayplacer)).

## Build Profiles

| Profile | Flags | Notes |
| --- | --- | --- |
| App Store-compatible | *(default)* | Uses only public APIs.
| `NON_MAS` | `OTHER_SWIFT_FLAGS="-D NON_MAS"` | Enables hooks for optional `displayplacer` automation (user consent required).

## Testing

- Run module tests via `swift test` (covering history buffers, formatters, display snapshot encoding, and DesignSystem rendering).
- Widget/UI snapshot smoke tests live under `Tests/` and can also execute inside Xcode when the package is resolved.

## Style Tokens

The `DesignSystem` package defines shared spacings, radii, and the `GlassPanel` layout wrapper to keep the Liquid Glass look consistent across app and widgets.

## Roadmap / TODOs

- Provide optional GPU metrics once public APIs are available.
- Extend NON_MAS automation with displayplacer integration and consent UI.
- Add localized strings and unit tests for AppIntent flows.
