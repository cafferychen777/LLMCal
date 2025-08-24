import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $appState.inputText)
                .frame(height: 100)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Button(action: {
                appState.processText()
            }) {
                if appState.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 4)
                } else {
                    Text("Add to Calendar")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.inputText.isEmpty || appState.isProcessing)
            
            if !appState.result.isEmpty {
                Text(appState.result)
                    .foregroundColor(appState.result.contains("Error") ? .red : .green)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
