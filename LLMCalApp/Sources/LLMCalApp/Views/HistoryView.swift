import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        List(viewModel.historyItems) { item in
            HistoryItemRow(item: item)
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.clearHistory()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.historyItems.isEmpty)
            }
        }
    }
}

struct HistoryItemRow: View {
    let item: HistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.originalText)
                    .font(.body)
                Spacer()
                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let eventTitle = item.eventTitle {
                Text("事件：\(eventTitle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(item.date, style: .time)
                    .font(.caption)
                
                if let duration = item.duration {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("\(duration) 分钟")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    
    func clearHistory() {
        historyItems.removeAll()
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let originalText: String
    let eventTitle: String?
    let date: Date
    let duration: Int?
    
    init(originalText: String, eventTitle: String? = nil, date: Date = Date(), duration: Int? = nil) {
        self.originalText = originalText
        self.eventTitle = eventTitle
        self.date = date
        self.duration = duration
    }
}
