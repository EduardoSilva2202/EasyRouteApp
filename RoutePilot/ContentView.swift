import MapKit
import SwiftUI

struct ContentView: View {
    @State private var stops: [RouteStop] = []
    @State private var isShowingAddStop = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.5, longitude: -3.0),
            span: MKCoordinateSpan(latitudeDelta: 7.0, longitudeDelta: 8.0)
        )
    )

    private let navy = Color(red: 0.03, green: 0.17, blue: 0.25)
    private let teal = Color(red: 0.19, green: 0.64, blue: 0.58)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        if let coordinate = stop.coordinate {
                            Marker("Stop \(index + 1)", coordinate: coordinate)
                                .tint(stop.isCompleted ? .green : .red)
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 20)
                    routePanel
                }
                .padding(.top, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingAddStop) {
                AddStopSheet { candidate in
                    let stop = RouteStop(
                        address: candidate.formattedAddress,
                        latitude: candidate.latitude,
                        longitude: candidate.longitude,
                        uprn: candidate.uprn,
                        udprn: candidate.udprn,
                        coordinateAccuracy: candidate.coordinateAccuracy
                    )
                    stops.append(stop)
                    if let coordinate = stop.coordinate {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                            )
                        )
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .tint(teal)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(teal)
                .frame(width: 48, height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .accessibilityHidden(true)

            Text("RoutePilot")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(navy)

            Spacer()

            Button {
                isShowingAddStop = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(teal, in: RoundedRectangle(cornerRadius: 15))
            }
            .accessibilityLabel("Add a stop")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var routePanel: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 4)

            HStack(alignment: .firstTextBaseline) {
                Text("Today's route")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(navy)

                Spacer()

                Text("\(stops.count) stops")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if stops.isEmpty {
                ContentUnavailableView(
                    "No stops yet",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Add a postcode and choose the exact address.")
                )
                .frame(maxWidth: .infinity)
                .frame(height: 145)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(stops.indices, id: \.self) { index in
                            let stop = stops[index]
                            StopRow(stop: stop, number: index + 1, navy: navy) {
                                toggle(stop)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            HStack(spacing: 12) {
                Button {
                    isShowingAddStop = true
                } label: {
                    Label("Add stop", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoutePilotPrimaryButtonStyle(color: teal))

                Button {} label: {
                    Label("Optimise", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoutePilotSecondaryButtonStyle())
                .disabled(true)
                .accessibilityHint("Route optimisation will be available after a routing service is connected.")
            }

            if !stops.isEmpty {
                Text("Address lookup is precise to the provider's available property coordinates. Route optimisation is not connected yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.13), radius: 18, y: 5)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    private func toggle(_ stop: RouteStop) {
        guard let index = stops.firstIndex(of: stop) else { return }
        stops[index].isCompleted.toggle()
    }
}

private struct StopRow: View {
    let stop: RouteStop
    let number: Int
    let navy: Color
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(stop.isCompleted ? Color.green : Color.red, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.address)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(navy)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(stop.coordinateAccuracy == "rooftop" ? "Property-level pin" :
                     stop.coordinateAccuracy == "postcode-centroid" ? "Approximate postcode pin" :
                     "Address saved; map pin unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onToggle) {
                Image(systemName: stop.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 25))
                    .foregroundStyle(stop.isCompleted ? Color.green : Color.gray.opacity(0.65))
            }
            .accessibilityLabel(stop.isCompleted ? "Mark stop as pending" : "Mark stop as complete")
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct AddStopSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postcode = ""
    @State private var candidates: [AddressCandidate] = []
    @State private var selectedCandidate: AddressCandidate?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var postcodeSuggestions: [String] = []

    let onAdd: (AddressCandidate) -> Void
    private let lookupService = AddressLookupService()
    private let navy = Color(red: 0.03, green: 0.17, blue: 0.25)
    private let teal = Color(red: 0.19, green: 0.64, blue: 0.58)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Find the exact address")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(navy)

                HStack(spacing: 10) {
                    TextField("Enter UK postcode", text: $postcode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityLabel("UK postcode")

                    Button {
                        Task { await searchAddresses() }
                    } label: {
                        if isSearching {
                            ProgressView().tint(.white)
                                .frame(width: 52, height: 48)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 48)
                        }
                    }
                    .background(teal, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(isSearching || postcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Search postcode")
                }

                Text("Choose the house, flat or business from the verified address list.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if !postcodeSuggestions.isEmpty {
                    Text("Did you mean: \(postcodeSuggestions.joined(separator: ", "))?")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !candidates.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(candidates) { candidate in
                                Button {
                                    selectedCandidate = candidate
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: selectedCandidate?.id == candidate.id ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(teal)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(candidate.formattedAddress)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(navy)
                                                .multilineTextAlignment(.leading)
                                            Text(candidate.coordinateAccuracyLabel)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        selectedCandidate?.id == candidate.id ? teal.opacity(0.12) : Color.gray.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }

                Button {
                    guard let selectedCandidate else { return }
                    onAdd(selectedCandidate)
                    dismiss()
                } label: {
                    Text("Add selected address")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoutePilotPrimaryButtonStyle(color: teal))
                .disabled(selectedCandidate == nil)

                Spacer(minLength: 0)
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func searchAddresses() async {
        isSearching = true
        errorMessage = nil
        postcodeSuggestions = []
        selectedCandidate = nil
        candidates = []
        defer { isSearching = false }

        do {
            candidates = try await lookupService.search(postcode: postcode)
            if candidates.isEmpty {
                errorMessage = "No delivery addresses were returned for this postcode."
            }
        } catch let error as AddressLookupError {
            errorMessage = error.localizedDescription
            postcodeSuggestions = error.postcodeSuggestions
        } catch {
            errorMessage = "Address lookup failed. Check the connection and try again."
        }
    }
}

private struct RoutePilotPrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct RoutePilotSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(red: 0.03, green: 0.17, blue: 0.25))
            .padding(.vertical, 15)
            .background(Color.gray.opacity(configuration.isPressed ? 0.18 : 0.11), in: RoundedRectangle(cornerRadius: 15))
    }
}
