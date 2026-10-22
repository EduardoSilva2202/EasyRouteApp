# RoutePilot

RoutePilot is a new iOS route-planning app for delivery and field-service drivers, starting with an original SwiftUI foundation.

## Current starter

- Native SwiftUI iOS app with a UK map.
- Postcode search returns a list of verified address choices from the RoutePilot address service.
- Selecting an address stores the full formatted address, UPRN/UDPRN when supplied, and coordinates.
- The map shows a pin for selected stops when coordinates are available.
- Route optimisation remains disabled until a road-routing provider is selected and integrated.

## Precise UK address lookup

The address lookup service in `backend/` is a small Node.js proxy for Ideal Postcodes. The provider key stays on the server and is never included in the iOS binary.

1. Create an Ideal Postcodes account and a key licensed for UK address data (PAF; add Multiple Residence coverage if the delivery workflow needs individual occupants in shared buildings).
2. Copy `backend/.env.example` to `backend/.env` and set `IDEAL_POSTCODES_API_KEY`. Never commit the real key.
3. Run the service from `backend/` with `npm run dev`. It listens on port 8787.
4. In Xcode, set the app Info.plist build setting `ROUTEPILOT_API_BASE_URL` to `http://127.0.0.1:8787` for the iOS Simulator. Use an HTTPS backend URL for a deployed service.
5. Run the app, enter a postcode, choose the exact house/flat/business, and confirm the property pin.

The provider can return address-level coordinates, but its documentation notes that some results only have postcode-centroid coordinates or no coordinates. The UI labels this difference so the app does not present an approximate location as a rooftop-accurate pin. Drivers should confirm the final entrance or access point where needed.

The service exposes `GET /health` and `GET /v1/addresses?postcode=...`. It validates UK postcode format, returns provider suggestions for a postcode typo, and does not return the provider API key or raw upstream error details.

The live address service requires an API key configured on the backend. Do not use real customer addresses until privacy, retention, and provider licensing are reviewed.

## Open on Mac

1. Check out `codex/routepilot-ios-mvp-20261022`.
2. Open `RoutePilot.xcodeproj` in Xcode.
3. Select the RoutePilot scheme and an iPhone simulator.
4. Build and run.

The iOS app currently keeps route stops in memory only. It is not yet connected to road directions, route optimisation, cloud sync, or persistent storage.

## Product direction

The interface and product are being designed independently from publicly described user needs and the screenshots supplied by the owner.
