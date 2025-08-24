import SwiftUI
import AppKit

@main
struct LLMCalApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra {
            MainWindowView()
                .environmentObject(appState)
                .frame(width: 800, height: 600)
        } label: {
            Image(systemName: "calendar")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .frame(width: 500, height: 400)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查 API Key
        if let apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey"), apiKey.isEmpty {
            let alert = NSAlert()
            alert.messageText = "缺少 API Key"
            alert.informativeText = "请在设置中配置 Anthropic API Key"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "打开设置")
            alert.addButton(withTitle: "稍后")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        
        // 设置应用图标
        if let iconURL = Bundle.appBundle.urlForImageResource("AppIcon") {
            NSApplication.shared.applicationIconImage = NSImage(contentsOf: iconURL)
        }
        
        // 改为正常应用程序
        NSApp.setActivationPolicy(.regular)
        
        // 激活应用并显示主窗口
        NSApp.activate(ignoringOtherApps: true)
        
        // 设置Dock图标
        if let window = NSApp.windows.first {
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
        
        // 初始化全局快捷键管理器
        hotKeyManager = HotKeyManager.shared
        
        // 请求辅助功能权限
        requestAccessibilityPermission()
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            // 显示提示
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "LLMCal 需要辅助功能权限来检测文本选择。请在系统偏好设置中授予权限。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "稍后")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var result: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    func processText() {
        guard !inputText.isEmpty else { return }
        isProcessing = true
        showError = false
        
        Task {
            do {
                let output = try await ShellExecutor.shared.execute(text: inputText)
                await MainActor.run {
                    if output.contains("错误：") {
                        showError = true
                        errorMessage = output
                    } else {
                        result = output
                    }
                    isProcessing = false
                    inputText = ""
                }
            } catch let error as LLMCalError {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isProcessing = false
                    
                    // 如果是 API Key 缺失错误，显示设置窗口
                    if case .apiKeyMissing = error {
                        DispatchQueue.main.async {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "发生错误：\(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}
