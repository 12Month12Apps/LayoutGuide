//
//  LayoutGuideApp.swift
//  LayoutGuide
//
//  Created by Veit Progl on 17.09.23.
//

import SwiftUI
import HotKey
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMenubarWindow = Self("toggleMenubarWindow")
}

@main
struct LayoutGuideApp: App {
    @NSApplicationDelegateAdaptor(PrivateAppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("SettingsAppp", id: "Settings") {
            LayoutApp(isPopup: false, appState: AppState(delegate: appDelegate))
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    init(delegate: PrivateAppDelegate) {
        KeyboardShortcuts.onKeyUp(for: .toggleMenubarWindow) { [self] in
            delegate.showPopOver()
        }
    }
}

class PrivateAppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var eventMonitor: Any?
    let hotKey = HotKey(key: .l, modifiers: [.command, .shift])

    func showPopOver() {
        if let button = self.statusBarItem.button {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
//        hotKey.keyDownHandler = {
            //        }
        
        let contentView = LayoutApp(isPopup: true, appState: AppState(delegate: self))
        
        NSApp.setActivationPolicy(.accessory)
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 800, height: 500)
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
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
