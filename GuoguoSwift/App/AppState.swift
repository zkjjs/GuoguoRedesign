import SwiftUI

enum RootDestination: String, CaseIterable, Identifiable {
    case home
    case collection
    case history
    case search
    case settings

    var id: String { rawValue }
}

final class AppState: ObservableObject {
    @Published var selectedRoot: RootDestination = .home
}
