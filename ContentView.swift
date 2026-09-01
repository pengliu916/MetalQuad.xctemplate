//___FILEHEADER___

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            MetalKitView()
                .ignoresSafeArea()
            
            InterfaceView()
                .padding(.all)
                .background(Color.black.opacity(0.8))
        }
        .persistentSystemOverlays(.hidden)
    }
}

struct InterfaceView: View {
    @State var param0: Float = 0.5
    
    var body: some View {
        HStack {
            Slider(value: $param0, in: 0.2 ... 1.0,
                   label: {Text(String(format: "Param0: %.2f", param0)).frame(width: 120)})
            .onChange(of: param0) { old, new in
                Renderer.shared.param0 = new
            }
        }
    }
}

#Preview {
    ContentView()
}
