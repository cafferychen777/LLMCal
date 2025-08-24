import SwiftUI
import os

struct SettingsView: View {
    @AppStorage("quickAddShortcut") private var quickAddShortcut = "N"
    @AppStorage("viewScheduleShortcut") private var viewScheduleShortcut = "V"
    @AppStorage("searchEventsShortcut") private var searchEventsShortcut = "F"
    @AppStorage("selectedLLM") private var selectedLLM = "Claude"
    @AppStorage("anthropicAPIKey") private var anthropicAPIKey = ""
    
    @State private var tempAnthropicAPIKey = ""
    @State private var showSaveSuccess = false
    
    private let llmOptions = ["Claude"]
    private let logger = Logger(subsystem: "com.llmcal.app", category: "SettingsView")
    
    var body: some View {
        Form {
            Section("LLM 设置") {
                Picker("选择 LLM 模型", selection: $selectedLLM) {
                    ForEach(llmOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                SecureField("Anthropic API Key", text: $tempAnthropicAPIKey)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        tempAnthropicAPIKey = anthropicAPIKey
                        logger.info("Current API Key length: \(anthropicAPIKey.count)")
                    }
                
                Button("保存 API Key") {
                    anthropicAPIKey = tempAnthropicAPIKey
                    logger.info("API Key saved, length: \(anthropicAPIKey.count)")
                    showSaveSuccess = true
                    
                    // 3秒后隐藏成功提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSaveSuccess = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempAnthropicAPIKey.isEmpty)
                
                if showSaveSuccess {
                    Text("API Key 已保存")
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            
            Section("快捷键设置") {
                HStack {
                    Text("快速添加事件：")
                    ShortcutButton(shortcut: $quickAddShortcut)
                }
                .help("快速添加新的日历事件")
                
                HStack {
                    Text("查看日程：")
                    ShortcutButton(shortcut: $viewScheduleShortcut)
                }
                .help("查看今日或本周日程")
                
                HStack {
                    Text("搜索事件：")
                    ShortcutButton(shortcut: $searchEventsShortcut)
                }
                .help("搜索已存在的日历事件")
            }
            .formStyle(.grouped)
            
            Section {
                Text("提示：所有快捷键都需要按住 Command + Option")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct ShortcutButton: View {
    @Binding var shortcut: String
    @State private var isRecording = false
    
    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            HStack(spacing: 4) {
                if shortcut.isEmpty {
                    Text("未设置")
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "command")
                    Image(systemName: "option")
                    Text(shortcut)
                }
            }
            .frame(width: 100, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .overlay {
            if isRecording {
                Color.black.opacity(0.2)
                    .onAppear {
                        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                            let key = event.characters?.uppercased() ?? ""
                            if !key.isEmpty {
                                shortcut = key
                                isRecording = false
                            }
                            return nil
                        }
                    }
            }
        }
    }
}
