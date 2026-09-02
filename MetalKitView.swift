//___FILEHEADER___

import SwiftUI
import MetalKit

struct MetalKitView {
    let param0: Float
}

#if os(macOS)
extension MetalKitView : NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        return Renderer.shared
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        Renderer.shared.param0 = param0
    }
}
#endif

#if os(iOS)
extension MetalKitView : UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        return Renderer.shared
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        Renderer.shared.param0 = param0
    }
}
#endif
