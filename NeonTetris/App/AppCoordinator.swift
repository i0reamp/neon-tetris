import SwiftUI

enum AppScreen: Equatable {
    case splash
    case mainMenu
    case game
    case settings
    case about
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var screen: AppScreen = .splash

    func go(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.28)) {
            self.screen = screen
        }
    }
}
