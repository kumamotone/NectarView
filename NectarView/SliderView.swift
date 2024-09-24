import SwiftUI

struct SliderView: View {
    @Binding var currentIndex: Int
    let totalImages: Int
    
    var body: some View {
        Slider(value: Binding(
            get: { Double(currentIndex) },
            set: { currentIndex = Int($0) }
        ), in: 0...Double(totalImages - 1), step: 1)
    }
}