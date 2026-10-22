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
                Map(position: $cameraPosition)
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
                AddStopSheet { address in
                    stops.append(RouteStop(address: address))
                }
                .presentationDetents([.medium])
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
                    description: Text("Add an address to start building your route.")
                )
                .frame(maxWidth: .infinity)
                .frame(height: 145)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
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
                    Label("Optimise", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoutePilotSecondaryButtonStyle())
                .disabled(true)
                .accessibilityHint("Route optimisation will be available after a routing service is connected.")
            }

            if !stops.isEmpty {
                Text("Route optimisation is not connected yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

            Text(stop.address)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(navy)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

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
    @State private var address = ""
    let onAdd: (String) -> Void

    private let navy = Color(red: 0.03, green: 0.17, blue: 0.25)
    private let teal = Color(red: 0.19, green: 0.64, blue: 0.58)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Add an address")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(navy)

                TextField("Postcode or full address", text: $address, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Postcode or full address")

                Text("Address search and map pin placement will be added when the address service is selected.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanedAddress.isEmpty else { return }
                    onAdd(cleanedAddress)
                    dismiss()
                } label: {
                    Text("Add stop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoutePilotPrimaryButtonStyle(color: teal))
                .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(22)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
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
