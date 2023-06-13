//
//  ContentView.swift
//  ARFunnyFace
//
//  Created by Ivan Nikitin on 05.06.2023.
//

import SwiftUI
import RealityKit
import ARKit

var arView: ARView!
var robot: Experience.Robot!

struct ContentView : View {
    
    // MARK: - Properties
    
    @State private var propId: Int = 0
    @State private var isFrontCamera: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        // 1
        ZStack {
            ARViewContainer(propId: $propId, isFrontCamera: $isFrontCamera).edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        self.isFrontCamera.toggle()
                    }) {
                        Image(systemName:  "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                // 3
                HStack {
                    
                    Spacer()
                    Button(action: {
                        self.propId = self.propId <= 0 ? 0 : self.propId - 1
                    }) {
                        Image("PreviousButton").clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        
                        self.takeSnapshot()
                    }) {
                        Image("ShutterButton").clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.propId = self.propId >= 3 ? 3 : self.propId + 1
                    }) {
                        Image("NextButton").clipShape(Circle())
                    }
                    Spacer()
                }
            }
            
        }
        
    }
    
    func takeSnapshot() {
        // 1
          arView.snapshot(saveToHDR: false) { (image) in
            // 2
            let compressedImage = UIImage(
              data: (image?.pngData())!)
        // 3
            UIImageWriteToSavedPhotosAlbum(
              compressedImage!, nil, nil, nil)
        }
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    
    // MARK: - Properties
    
    @Binding var propId: Int
    @Binding var isFrontCamera: Bool
    
    // MARK: - Functions
    
    func makeUIView(context: Context) -> ARView {
        
        arView = ARView(frame: .zero)
        
        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadEyes()
        
        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        arView.session.delegate = context.coordinator
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.removeAll()
        if isFrontCamera {
            robot = nil
            let arConfiguration = ARFaceTrackingConfiguration()
            uiView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
            
            switch propId {
            case 0:
                guard let arAnchor = try? Experience.loadEyes() else { break
                }
                uiView.scene.anchors.append(arAnchor)
                        
            case 1:
                guard let arAnchor = try? Experience.loadGlasses() else { break
                }
                uiView.scene.anchors.append(arAnchor)
            case 2:
                guard let arAnchor = try? Experience.loadMustache() else { break
                }
                uiView.scene.anchors.append(arAnchor)
            case 3:
                guard let arAnchor = try? Experience.loadRobot() else { break
                }
                uiView.scene.anchors.append(arAnchor)
                robot = arAnchor
            default:
                break
            }
        } else {
            let arConfiguration = ARWorldTrackingConfiguration()
            arConfiguration.planeDetection = .horizontal
            uiView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
            
                guard let arAnchor = try? Experience.loadFurniture() else {
                    print("Not detected arAnchor")
                    return
                }
                uiView.scene.anchors.append(arAnchor)
        }
    }
    
    func makeCoordinator() -> ARSessionDelegate {
        ARDelegateHandler(self)
    }
    
    class ARDelegateHandler: NSObject, ARSessionDelegate {
        var arViewContainer: ARViewContainer
        var isLasersDone = true
        
        init(_ control: ARViewContainer) {
            arViewContainer = control
            super.init()
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard robot != nil else { return }
            
            var faceAnchor: ARFaceAnchor?
            for anchor in anchors {
                if let a = anchor as? ARFaceAnchor {
                    faceAnchor = a
                }
            }
            
            let blendShapes = faceAnchor?.blendShapes
            let eyeBlinkLeft = blendShapes?[.eyeBlinkLeft]?.floatValue
            let eyeBlinkRight = blendShapes?[.eyeBlinkRight]?.floatValue
            
            let browInnerUp = blendShapes?[.browInnerUp]?.floatValue
            let browDownLeft = blendShapes?[.browDownLeft]?.floatValue
            let browDownRight = blendShapes?[.browDownRight]?.floatValue
            
            let jawOpen = blendShapes?[.jawOpen]?.floatValue
            
            robot.eyeLidL?.orientation = simd_mul(
                simd_quatf(angle: Deg2Rad(-120 + (90 * eyeBlinkLeft!)),
                           axis: [1,0,0]),
                simd_quatf(angle: Deg2Rad((30 * browDownLeft!) - (30 * browInnerUp!)),
                           axis: [0,0,1]))

            robot.eyeLidR?.orientation = simd_mul(
                simd_quatf(angle: Deg2Rad(-120 + (90 * eyeBlinkRight!)),
                           axis: [1,0,0]),
                simd_quatf(angle: Deg2Rad((-30 * browDownRight!) - (-30 * browInnerUp!)),
                           axis: [0,0,1]))
           
            robot.jaw?.orientation = simd_quatf(
              angle: Deg2Rad(-100 + (60 * jawOpen!)),
              axis: [1, 0, 0])
            
            
            if (self.isLasersDone == true && jawOpen! > 0.9) {
                self.isLasersDone = false
                robot.notifications.showLasers.post()
                robot.actions.lasersDone.onAction = { _ in
                    self.isLasersDone = true
                }
            }
            
        }
        
        func Deg2Rad(_ value: Float) -> Float {
            return value * .pi / 180
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
