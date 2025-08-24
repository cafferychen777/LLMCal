import Foundation
import Carbon
import AppKit
import os

class HotKeyManager {
    static let shared = HotKeyManager()
    private var eventHandler: EventHandlerRef?
    private let logger = Logger(subsystem: "com.llmcal.app", category: "HotKeyManager")
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.llmcal.app.hotkeymanager")
    
    private init() {
        logger.info("Initializing HotKeyManager")
        registerHotKey()
    }
    
    private func registerHotKey() {
        logger.info("Registering hotkey Command + Option + N")
        
        var hotKeyRef: EventHotKeyRef?
        
        // 创建唯一的签名
        let signature: OSType = 0x4C4C4D43 // "LLMC" in hex
        
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = signature
        gMyHotKeyID.id = UInt32(kVK_ANSI_N)
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)
        
        // 注册事件处理程序
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(GetApplicationEventTarget(), { (_, eventRef, userData) -> OSStatus in
            guard let userData = userData,
                  let eventRef = eventRef else {
                return OSStatus(eventNotHandledErr)
            }
            
            let this = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            return this.handleHotKeyEvent(eventRef)
            
        }, 1, &eventType, selfPtr, &eventHandler)
        
        if status != noErr {
            logger.error("Failed to install event handler: \(status)")
            return
        }
        
        // 注册热键
        let hotKeyStatus = RegisterEventHotKey(UInt32(kVK_ANSI_N),
                                             UInt32(cmdKey + optionKey),
                                             gMyHotKeyID,
                                             GetApplicationEventTarget(),
                                             0,
                                             &hotKeyRef)
        
        if hotKeyStatus != noErr {
            logger.error("Failed to register hotkey: \(hotKeyStatus)")
        } else {
            logger.info("Successfully registered hotkey")
        }
    }
    
    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 如果已经在处理中，就忽略这次事件
            guard !self.isProcessing else {
                self.logger.info("Already processing a hotkey event, ignoring this one")
                return
            }
            
            self.isProcessing = true
            self.logger.info("Hotkey pressed, getting selected text")
            
            Task {
                do {
                    let selectedText = try await self.getSelectedText()
                    self.logger.info("Selected text: \(selectedText)")
                    
                    // 处理选中的文本
                    let output = try await ShellExecutor.shared.execute(text: selectedText)
                    self.logger.info("Shell execution result: \(output)")
                    
                    // 显示成功通知
                    await self.showNotification(title: "成功", message: "事件已添加到日历")
                    
                } catch {
                    self.logger.error("Error handling hotkey event: \(error.localizedDescription)")
                    // 显示错误通知
                    await self.showNotification(title: "错误", message: error.localizedDescription)
                }
                
                // 处理完成后重置标志
                self.isProcessing = false
            }
        }
        
        return noErr
    }
    
    private func showNotification(title: String, message: String) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            
            logger.info("Showing notification: \(title) - \(message)")
            alert.runModal()
        }
    }
    
    private func getSelectedText() async throws -> String {
        logger.info("Getting selected text")
        
        // 模拟按下 Command + C
        let source = CGEventSource(stateID: .hidSystemState)
        
        // 创建按键事件
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        // 添加 Command 修饰键
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        // 发送事件
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        // 等待剪贴板更新
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // 获取剪贴板内容
        guard let text = NSPasteboard.general.string(forType: .string) else {
            throw NSError(domain: "com.llmcal.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取选中的文本"])
        }
        
        logger.info("Successfully got selected text: \(text)")
        return text
    }
    
    deinit {
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
