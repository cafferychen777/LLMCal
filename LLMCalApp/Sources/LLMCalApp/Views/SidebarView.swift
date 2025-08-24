import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem
    
    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            NavigationLink(value: item) {
                Label {
                    Text(item.title)
                } icon: {
                    Image(systemName: item.icon)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
