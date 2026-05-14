import SwiftUI
import Foundation

enum AppScreen: String, Equatable {
    case splash
    case mainMenu
    case game
    case settings
    case about

    init?(launchArg: String?) {
        guard let raw = launchArg?.lowercased() else { return nil }
        switch raw {
        case "splash": self = .splash
        case "mainmenu", "menu", "main_menu", "main-menu": self = .mainMenu
        case "game", "play": self = .game
        case "settings": self = .settings
        case "about": self = .about
        default: return nil
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var screen: AppScreen

    init(initial: AppScreen = .splash) {
        self.screen = initial
    }

    func go(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.28)) {
            self.screen = screen
        }
    }
}
