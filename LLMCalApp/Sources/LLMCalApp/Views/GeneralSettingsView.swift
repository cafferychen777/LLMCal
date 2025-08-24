import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("defaultCalendar") private var defaultCalendar = "默认日历"
    @AppStorage("defaultDuration") private var defaultDuration = 60
    
    var body: some View {
        Form {
            Section("基本设置") {
                Toggle("开机启动", isOn: $launchAtLogin)
                Toggle("在程序坞中显示", isOn: $showInDock)
            }
            
            Section("日历设置") {
                Picker("默认日历", selection: $defaultCalendar) {
                    Text("默认日历").tag("默认日历")
                    Text("工作").tag("工作")
                    Text("个人").tag("个人")
                }
                
                Stepper("默认时长: \(defaultDuration)分钟", value: $defaultDuration, in: 15...240, step: 15)
            }
            
            Section("关于") {
                LabeledContent("版本", value: "1.0.0")
                Link("查看源代码", destination: URL(string: "https://github.com/cafferychen777/LLMCal")!)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
