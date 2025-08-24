import SwiftUI

struct ServicesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ServicesViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if appState.isProcessing {
                ProgressView("正在处理...")
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            } else if appState.showError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text(appState.errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    
                    if appState.errorMessage.contains("API Key") {
                        Button("打开设置") {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            } else {
                Form {
                    Section {
                        ForEach($viewModel.services) { $service in
                            ServiceRow(service: $service)
                        }
                    } header: {
                        Text("LLM服务")
                    } footer: {
                        Text("选择并配置要使用的LLM服务")
                    }
                }
                .formStyle(.grouped)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ServiceRow: View {
    @Binding var service: LLMService
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $service.isEnabled) {
                HStack {
                    Image(service.icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(service.name)
                }
            }
            
            if service.isEnabled {
                TextField("API Key", text: $service.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                if !service.modelOptions.isEmpty {
                    Picker("模型", selection: $service.selectedModel) {
                        ForEach(service.modelOptions, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

class ServicesViewModel: ObservableObject {
    @Published var services: [LLMService] = [
        LLMService(name: "OpenAI", icon: "openai", modelOptions: ["gpt-3.5-turbo", "gpt-4"]),
        LLMService(name: "Claude", icon: "anthropic", modelOptions: ["claude-2", "claude-instant"]),
        LLMService(name: "Gemini", icon: "google", modelOptions: ["gemini-pro"])
    ]
}

struct LLMService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var isEnabled: Bool = false
    var apiKey: String = ""
    let modelOptions: [String]
    var selectedModel: String = ""
    
    init(name: String, icon: String, modelOptions: [String]) {
        self.name = name
        self.icon = icon
        self.modelOptions = modelOptions
        self.selectedModel = modelOptions.first ?? ""
    }
}
