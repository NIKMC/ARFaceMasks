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

struct ContentView : View {
    
    // MARK: - Properties
    
    @State private var propId: Int = 0
    @State private var isFrontCamera: Bool = false
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
                        self.propId = self.propId >= 2 ? 2 : self.propId + 1
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
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.removeAll()
        if isFrontCamera {
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
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
