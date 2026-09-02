//___FILEHEADER___

import SwiftUI

struct ContentView: View {
    @State private var param0: Float = Renderer.shared.param0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MetalKitView(param0: param0)
                .ignoresSafeArea()
            
            InterfaceView(param0: $param0)
                .padding(.all)
                .background(Color.black.opacity(0.8))
        }
        .persistentSystemOverlays(.hidden)
    }
}

struct InterfaceView: View {
    @Binding var param0: Float
    
    var body: some View {
        HStack {
            Slider(value: $param0, in: 0.2 ... 1.0,
                   label: {Text(String(format: "Param0: %.2f", param0)).frame(width: 120)})
        }
    }
}

#Preview {
    ContentView()
}
