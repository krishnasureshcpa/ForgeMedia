import SwiftUI
import ForgeMediaDomain
import ForgeMediaData
import ForgeMediaMedia
import ForgeMediaAI

extension Notification.Name {
    static let forgeOpenMainWindow = Notification.Name("ForgeMediaOpenMainWindow")
}

/// @main entry point for the ForgeMedia macOS app.
///
/// WindowGroup (not Window) is intentional: it guarantees a window is presented on
/// every launch, even when the user previously closed it. The AppDelegate posts a
/// notification that the MenuBarExtra body observes so it can call openWindow(id:)
/// from within the SwiftUI environment — the only context where that action works.
@main
struct ForgeMediaApp: App {
    @State private var model: AppModel

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let db = try! DatabaseService.inMemory()
        let engine = ForgeMediaApp.resolveProcessingEngine()
        let agent = StubLocalAgentRouter()
        self.model = AppModel(db: db, engine: engine, agent: agent)
    }

    private static func resolveProcessingEngine() -> ProcessingEngine {
        let candidatePairs = [
            ("/opt/homebrew/bin/ffmpeg", "/opt/homebrew/bin/ffprobe"),
            ("/usr/local/bin/ffmpeg", "/usr/local/bin/ffprobe"),
            ("/usr/bin/ffmpeg", "/usr/bin/ffprobe")
        ]
        for (ffmpeg, ffprobe) in candidatePairs where FileManager.default.isExecutableFile(atPath: ffmpeg) {
            let probePath = FileManager.default.isExecutableFile(atPath: ffprobe) ? ffprobe : nil
            return CompositeProcessingEngine(
                defaultEngine: FFmpegProcessRunner(
                    ffmpegPath: ffmpeg,
                    ffprobePath: probePath
                ),
                openDubbingEngine: OpenDubbingBatchEngine(),
                pipelineEngine: RealPipelineEngine(ffmpegPath: ffmpeg, ffprobePath: probePath)
            )
        }
        return FakeProcessingEngine()
    }

    var body: some Scene {
        // WindowGroup guarantees a window on every launch and Dock-click reopen.
        WindowGroup("ForgeMedia", id: "main") {
            MainWindow(model: model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Show ForgeMedia Window") {
                    NSApp.windows
                        .filter { $0.canBecomeMain }
                        .forEach { $0.makeKeyAndOrderFront(nil) }
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }

        // Menu bar status item — also acts as openWindow bridge on launch.
        MenuBarExtra("ForgeMedia", systemImage: "film") {
            MenuBarView(model: model)
                .openMainWindowBridge()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - openWindow bridge
//
// openWindow(id:) only works inside a SwiftUI view hierarchy.
// The MenuBarExtra body stays alive as long as the app runs, making it the
// reliable host for the post-launch notification → openWindow(id: "main") call.

private extension View {
    func openMainWindowBridge() -> some View {
        modifier(OpenMainWindowModifier())
    }
}

private struct OpenMainWindowModifier: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .forgeOpenMainWindow)) { _ in
                openWindow(id: "main")
            }
    }
}

// MARK: - NSApplicationDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Slight delay so the MenuBarExtra view is mounted before the notification fires.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: .forgeOpenMainWindow, object: nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NotificationCenter.default.post(name: .forgeOpenMainWindow, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.windows
                    .filter { $0.canBecomeMain }
                    .forEach { $0.makeKeyAndOrderFront(nil) }
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running as a menu-bar app when the main window is closed.
        return false
    }
}
