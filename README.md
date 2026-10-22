# RoutePilot

RoutePilot is a new iOS route-planning app for delivery and field-service drivers, starting with an original SwiftUI foundation.

## Current starter

- Native SwiftUI iOS app project.
- Map-first home screen centred on the UK.
- Add a stop by entering an address.
- Mark a stop complete or reopen it.
- Route optimisation is intentionally disabled until a road-routing provider is selected and integrated.

This is the clean starting point for the RoutePilot MVP. It is not yet connected to geocoding, road directions, route optimisation, cloud sync, or persistent storage.

## Open on Mac

1. Clone this repository and check out `codex/routepilot-ios-mvp-20261022`.
2. Open `RoutePilot.xcodeproj` in Xcode.
3. Select the RoutePilot scheme and an iPhone simulator.
4. Build and run.

The app currently uses demo/local state. Do not enter real customer addresses until storage, privacy, and provider choices are implemented.

## Product direction

See the RoutePilot functional specification and delivery plan prepared alongside this repository. The interface and product are being designed independently from publicly described user needs and the screenshots supplied by the owner.
