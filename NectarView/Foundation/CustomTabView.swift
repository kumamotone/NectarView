import SwiftUI

// https://stackoverflow.com/a/78754366/5658829
public struct CustomTabView: View {
    private let titles: [String]
    private let icons: [String]
    private let tabViews: [AnyView]

    @State private var selection = 0
    @State private var indexHovered = -1

    public init(content: [(title: String, icon: String, view: AnyView)]) {
        self.titles = content.map { $0.title }
        self.icons = content.map { $0.icon }
        self.tabViews = content.map { $0.view }
    }

    public var tabBar: some View {
        HStack {
            Spacer()
            ForEach(0..<titles.count, id: \.self) { index in
                VStack(spacing: 4) {
                    Image(systemName: self.icons[index])
                        .font(.system(size: 24))
                        .frame(height: 24)
                    Text(self.titles[index])
                        .font(.caption)
                }
                .frame(width: 80, height: 50)
                .padding(.vertical, 8)
                .background(((self.selection == index) || (self.indexHovered == index)) ? Color.secondary.opacity(0.2) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundColor(self.selection == index ? Color.primary : Color.secondary)
                .onHover(perform: { hovering in
                    if hovering {
                        indexHovered = index
                    } else {
                        indexHovered = -1
                    }
                })
                .onTapGesture {
                    self.selection = index
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    public var body: some View {
        VStack(spacing: 0) {
            tabBar
            tabViews[selection]
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(0)
    }
}
