import SwiftUI

struct InstantTooltip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .padding(6)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(4)
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct TooltipModifier: ViewModifier {
    let tooltip: String
    @State private var isShowing = false
    @State private var tooltipSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isShowing {
                        InstantTooltip(text: tooltip)
                            .background(GeometryReader { tooltipGeometry in
                                Color.clear.preference(key: TooltipSizePreferenceKey.self, value: tooltipGeometry.size)
                            })
                            .onPreferenceChange(TooltipSizePreferenceKey.self) { size in
                                tooltipSize = size
                            }
                            .position(tooltipPosition(in: geometry))
                    }
                }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowing = hovering
                }
            }
    }
    
    private func tooltipPosition(in geometry: GeometryProxy) -> CGPoint {
        let x = geometry.size.width / 2
        let y = geometry.size.height + 24 // 固定で24px下に配置
        return CGPoint(x: x, y: y)
    }
}

extension View {
    func instantTooltip(_ text: String) -> some View {
        self.modifier(TooltipModifier(tooltip: text))
    }
}

struct TooltipSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}