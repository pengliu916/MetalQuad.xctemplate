//___FILEHEADER___

import MetalKit
import SwiftUI
import OSLog

fileprivate let log = Logger(subsystem: "___PROJECTNAME___", category: "Renderer")
fileprivate let frameBufCnt = 3
fileprivate let pixelFormat = MTLPixelFormat.rgba16Float
fileprivate let sampleCnt = 1

class Renderer: MTKView, MTKViewDelegate {
    static let shared = Renderer()
    var param0: Float = 0.5
    var viewAspectRatio: CGFloat = 1.0
    
    unowned var dev: MTLDevice
    let cmdQueue: MTLCommandQueue
    let psoGFX: MTLRenderPipelineState
    let vs: MTLFunction
    let ps: MTLFunction
    let semaphore = DispatchSemaphore(value: frameBufCnt)
    var bufConst = ConstBuf()
    
    private var preFrameTimeStamp: CFTimeInterval = 0.0
    private var curFrameTimeStamp: CFTimeInterval = 0.0
    private var startFrameTimeStamp: CFTimeInterval = 0.0
    private var deltaTime: CFTimeInterval = 0.0
    private var elapsedTime: CFTimeInterval = 0.0
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private init() {
        guard let _dev = MTLCreateSystemDefaultDevice() else {fatalError("failed to create MTLDevice")}
        dev = _dev
        
        guard let _queue = dev.makeCommandQueue() else {fatalError("failed to make queue")}
        cmdQueue = _queue

        let lib: MTLLibrary
        do {lib = try dev.makeDefaultLibrary(bundle: .main)}
        catch {fatalError("failed to make lib: \(error)")}

        vs = Renderer.makeGPUFunc(lib, name: "vs_quad")
        ps = Renderer.makeGPUFunc(lib, name: "ps_quad")

        psoGFX = Renderer.makeGFXPSO(dev: dev, label: "Quad", vs: vs, ps: ps,
                                     framePixFormat: pixelFormat, sampleCnt: sampleCnt)

        super.init(frame: CGRect(), device: dev)

        self.delegate = self
        self.device = dev
        self.colorPixelFormat = pixelFormat
        self.sampleCount = sampleCnt
        
        // enable EDR support
        let caMtlLayer = self.layer as! CAMetalLayer
        caMtlLayer.wantsExtendedDynamicRangeContent = true
        caMtlLayer.pixelFormat = pixelFormat
        let name =  CGColorSpace.extendedLinearDisplayP3
        let colorSpace = CGColorSpace(name: name)
        caMtlLayer.colorspace = colorSpace
        
        startFrameTimeStamp = CACurrentMediaTime()
    }
    
    private static func makeGPUFunc(_ lib: MTLLibrary, name: String) -> MTLFunction {
        guard let bolb = lib.makeFunction(name: name)
        else {fatalError("Failed to create MTLFunction \(name)")}
        log.info("MTLFunction \(name) created")
        return bolb
    }
    
    private static func makeGFXPSO(dev: MTLDevice, label: String,
                                   vs: MTLFunction, ps: MTLFunction,
                                   framePixFormat: MTLPixelFormat, sampleCnt: Int) -> MTLRenderPipelineState {
        let psoDesc = MTLRenderPipelineDescriptor()
        psoDesc.label = label
        psoDesc.rasterSampleCount = sampleCnt
        psoDesc.vertexFunction = vs
        psoDesc.fragmentFunction = ps
        psoDesc.colorAttachments[0].pixelFormat = framePixFormat
        do {
            let pso = try dev.makeRenderPipelineState(descriptor: psoDesc)
            log.info("PSO: \(label) created")
            return pso
        } catch {
            fatalError("Failed to create PSO \(label): \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        bufConst.fViewAspectRatio = Float(size.width/size.height)
    }
    
    func draw(in view: MTKView) {
        preFrameTimeStamp = curFrameTimeStamp
        curFrameTimeStamp = CACurrentMediaTime()
        deltaTime = curFrameTimeStamp - preFrameTimeStamp
        elapsedTime = curFrameTimeStamp - startFrameTimeStamp
        
        bufConst.fParam0 = param0
        bufConst.fTime = Float(elapsedTime)
#if os(macOS)
        bufConst.fEDR = Float(window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1.0)
#else
        bufConst.fEDR = Float(window?.screen.currentEDRHeadroom ?? 1.0)
#endif
        
        _ = semaphore.wait(timeout: .distantFuture)
        guard let cmdBuf = cmdQueue.makeCommandBuffer() else {log.error("Faild to get cmdBuf"); semaphore.signal(); return}
        let semaphore = semaphore
        cmdBuf.addCompletedHandler{ cb in
            if let err = cb.error {log.error("cmdBuf failed: \(err.localizedDescription)")}
            semaphore.signal()
        }
        
        guard let rpd = view.currentRenderPassDescriptor
        else {log.error("Failed to get view's rpd"); semaphore.signal(); return}
        
        guard let rce = cmdBuf.makeRenderCommandEncoder(descriptor: rpd)
        else {log.error("Failed to get encoder"); semaphore.signal(); return}
        
        rce.setRenderPipelineState(psoGFX)
        rce.setVertexBytes(&bufConst, length: MemoryLayout<ConstBuf>.size, index: 0)
        rce.setFragmentBytes(&bufConst, length: MemoryLayout<ConstBuf>.size, index: 0)
        rce.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        rce.endEncoding()
        
        if let drawable = view.currentDrawable {
            cmdBuf.present(drawable)
        }
        
        cmdBuf.commit()
    }
}
