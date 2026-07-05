import SwiftUI
import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private var hotKeyRef: EventHotKeyRef?
    let timeZoneManager = TimeZoneManager()

    private enum HotKeyID {
        static let toggleMenu: UInt32 = 1
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        registerHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotKey()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "deskclock",
                accessibilityDescription: "Zonedial"
            )
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
    }

    @objc private func statusItemClicked() {
        let menu = buildMenu()
        guard let button = statusItem.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY - 4), in: button)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        let menuItem = NSMenuItem()
        let contentView = MainPanelView()
            .environmentObject(timeZoneManager)
        let hostingView = NSHostingView(rootView: contentView)
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: 360, height: max(fittingSize.height, 480))
        menuItem.view = hostingView
        menu.addItem(menuItem)

        return menu
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    // MARK: - Global HotKey

    private func registerHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                guard let event = event else { return -1 }
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if err == noErr, hotKeyID.id == HotKeyID.toggleMenu {
                    DispatchQueue.main.async {
                        let delegate = NSApp.delegate as? AppDelegate
                        delegate?.statusItemClicked()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        let cmdShiftZ = UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue)
        let keyZ = UInt32(kVK_ANSI_Z)

        var hotKeyID = EventHotKeyID(signature: 0, id: HotKeyID.toggleMenu)
        RegisterEventHotKey(keyZ, cmdShiftZ, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
