import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        try? SMAppService.mainApp.register()
    }
}
