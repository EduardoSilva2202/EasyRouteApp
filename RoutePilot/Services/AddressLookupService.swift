import Foundation

struct AddressCandidate: Codable, Identifiable, Equatable {
    let id: String
    let formattedAddress: String
    let postcode: String
    let latitude: Double?
    let longitude: Double?
    let uprn: String?
    let udprn: String?
    let coordinateAccuracy: String

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var coordinateAccuracyLabel: String {
        switch coordinateAccuracy {
        case "rooftop": return "Property-level map location"
        case "postcode-centroid": return "Approximate postcode location"
        default: return "No map location supplied"
        }
    }
}

private struct AddressLookupResponse: Decodable {
    let addresses: [AddressCandidate]
}

private struct AddressLookupErrorResponse: Decodable {
    let error: String
    let suggestions: [String]?
}

enum AddressLookupError: LocalizedError {
    case invalidPostcode
    case notFound([String])
    case serviceUnavailable
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPostcode:
            return "Enter a valid UK postcode."
        case .notFound:
            return "No addresses were found for that postcode."
        case .serviceUnavailable:
            return "Address lookup is not connected. Start the RoutePilot address service and try again."
        case .requestFailed(let message):
            return message
        }
    }

    var postcodeSuggestions: [String] {
        if case .notFound(let suggestions) = self { return suggestions }
        return []
    }
}

struct AddressLookupService {
    private var baseURL: URL {
        let configured = Bundle.main.object(forInfoDictionaryKey: "ROUTEPILOT_API_BASE_URL") as? String
        return URL(string: configured ?? "http://127.0.0.1:8787")!
    }

    func search(postcode: String) async throws -> [AddressCandidate] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/addresses"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "postcode", value: postcode)]

        guard let url = components?.url else {
            throw AddressLookupError.serviceUnavailable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AddressLookupError.serviceUnavailable
            }

            if http.statusCode == 404 {
                let errorBody = try? JSONDecoder().decode(AddressLookupErrorResponse.self, from: data)
                throw AddressLookupError.notFound(errorBody?.suggestions ?? [])
            }
            if http.statusCode == 400 {
                throw AddressLookupError.invalidPostcode
            }
            if http.statusCode == 503 || http.statusCode == 502 {
                throw AddressLookupError.serviceUnavailable
            }
            guard (200..<300).contains(http.statusCode) else {
                throw AddressLookupError.requestFailed("Address lookup failed (HTTP \(http.statusCode)).")
            }

            return try JSONDecoder().decode(AddressLookupResponse.self, from: data).addresses
        } catch let error as AddressLookupError {
            throw error
        } catch {
            throw AddressLookupError.serviceUnavailable
        }
    }
}
