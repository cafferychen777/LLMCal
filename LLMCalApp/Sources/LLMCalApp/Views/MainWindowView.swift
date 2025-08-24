import SwiftUI

struct MainWindowView: View {
    @State private var selectedSidebarItem: SidebarItem = .settings
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSidebarItem)
                .frame(minWidth: 200)
        } detail: {
            switch selectedSidebarItem {
            case .settings:
                SettingsView()
            case .services:
                ServicesView()
            case .history:
                HistoryView()
            case .favorites:
                FavoritesView()
            case .general:
                GeneralSettingsView()
            }
        }
        .navigationTitle(selectedSidebarItem.title)
    }
}

enum SidebarItem: String, CaseIterable {
    case settings = "设置"
    case services = "服务"
    case history = "历史记录"
    case favorites = "收藏夹"
    case general = "通用设置"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .settings: return "gear"
        case .services: return "server.rack"
        case .history: return "clock"
        case .favorites: return "star"
        case .general: return "slider.horizontal.3"
        }
    }
}
