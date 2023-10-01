//
//  LayoutGuideApp.swift
//  LayoutGuide
//
//  Created by Veit Progl on 17.09.23.
//

import SwiftUI
import HotKey

@main
struct LayoutGuideApp: App {
    @NSApplicationDelegateAdaptor(PrivateAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            SettingsApp(isPopup: false)
        }
        
        Window("SettingsAppp", id: "Settings") {
            SettingsApp(isPopup: false)
        }
    }
}

private class PrivateAppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var eventMonitor: Any?
    let hotKey = HotKey(key: .d, modifiers: [.command, .shift])

    func applicationDidFinishLaunching(_ notification: Notification) {
//        setupGlobalEventMonitor()
        hotKey.keyDownHandler = {
            if let button = self.statusBarItem.button {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        
        let contentView = SettingsApp(isPopup: true)
        
        NSApp.setActivationPolicy(.accessory)
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Create the status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = statusBarItem.button {
            button.image = NSImage(named: NSImage.Name("statusIcon")) // Remember to add this image in your Assets
            button.action = #selector(togglePopover(_:))
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusBarItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    private func setupGlobalEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Cmd + Shift + P as the shortcut
            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.keyCode == 35 {
                self.togglePopover(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
