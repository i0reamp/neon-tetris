import SwiftUI

@main
struct NeonTetrisApp: App {
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var settings = SettingsStore()

    init() {
        // Launch arg `-NEON_INITIAL_SCREEN <name>` jumps straight to a screen.
        // Used by the CI screenshot workflow so we don't depend on simulator
        // tap automation (which simctl doesn't actually provide).
        let raw = UserDefaults.standard.string(forKey: "NEON_INITIAL_SCREEN")
        let initial = AppScreen(launchArg: raw) ?? .splash
        _coordinator = StateObject(wrappedValue: AppCoordinator(initial: initial))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch coordinator.screen {
            case .splash:
                SplashView().transition(.opacity)
            case .mainMenu:
                MainMenuView().transition(.opacity)
            case .game:
                GameView().transition(.opacity)
            case .settings:
                SettingsView().transition(.opacity)
            case .about:
                AboutView().transition(.opacity)
            }
        }
    }
}
