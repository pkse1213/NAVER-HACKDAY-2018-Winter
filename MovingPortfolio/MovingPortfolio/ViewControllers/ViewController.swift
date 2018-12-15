//
//  ViewController.swift
//  MovingPortfolio
//
//  Created by 박세은 on 2018. 11. 26..
//  Copyright © 2018년 박세은. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var imagepPopUpView: UIView!
    @IBOutlet weak var infoPopUpView: UIView!
    
    var viewController: UIViewController!
    var actions: [String: (CGSize, SCNNode) -> Void]?
    var touchesBeganActions: [String : UIView]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        imagepPopUpView.isHidden = true
        imagepPopUpView.layer.cornerRadius = 10
        
        infoPopUpView.isHidden = true
        infoPopUpView.layer.cornerRadius = 10
        
        viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyInfoTbV")
        actions = ["MyProfile" : searchMyProfileImage]
        touchesBeganActions = ["infoViewNode" : infoPopUpView, "simpleViewNode" : imagepPopUpView]
    }
    
    @IBAction func closeViewAction(_ sender: UIButton) {
        sender.superview?.isHidden = true
    }
    
    func popUpView(_ view: UIView){
        view.isHidden = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let imageNode = sceneView.scene.rootNode.childNode(withName: "MyProfile", recursively: false) else { return }
        
        let touchPoint = touch.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchPoint, options: nil)
        
        if let resultNode = hitResults.first?.node {
            if let nodeName = resultNode.name {
                print(nodeName)
                if let view = touchesBeganActions?[nodeName] {
                    popUpView(view)
                    return
                }
            }
            if let node = videoNode(by: resultNode, position: SCNVector3(0.15, 0, 0)) {
                imageNode.addChildNode(node)
                return
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARImageTrackingConfiguration()
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 10
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let image = imageAnchor.referenceImage
        guard let imageName = image.name else { return }
        let imageSize = image.physicalSize
        node.name = imageName
        if let imageDetectionAction = actions?[imageName] {
            imageDetectionAction(imageSize, node)
        }
    }
    
    func searchMyProfileImage(with size: CGSize, at node: SCNNode) {
        let viewPlaneNode = viewNode(with: CGSize(width: size.width, height: size.height), name: "viewPlaneNode", position: SCNVector3(-size.width-0.01, 0, 0), view: viewController.view)
        node.addChildNode(viewPlaneNode)
       
        let simpleView = UIView()
        let simpleViewNode = viewNode(with: CGSize(width: 0.05, height: 0.025), name: "simpleViewNode", position: SCNVector3(0, 0, -size.height/2-0.03
        ), view: simpleView)
        let infoViewNode = viewNode(with: CGSize(width: 0.05, height: 0.025), name: "infoViewNode", position: SCNVector3(-size.width-0.01, 0, -size.height/2-0.03
        ), view: simpleView)
        node.addChildNode(infoViewNode)
        node.addChildNode(simpleViewNode)
        
        let zPositionIndex = [0.25, 0.75, -0.25, -0.75]
        for i in 0...3 {
            let appPlaneNode = appIconNode(with: CGSize(width: size.height/4-0.002, height: size.height/4-0.002), name: "appicon\(i+1)", position: SCNVector3(size.width/2 + 0.03, 0, size.width*CGFloat(zPositionIndex[i])))
            node.addChildNode(appPlaneNode)
        }
    }
    
    func textNode(title: String, position: SCNVector3) -> SCNNode {
        let text = SCNText(string: title, extrusionDepth: 10)
        let textNode = SCNNode(geometry: text)
        textNode.position = position
        return textNode
    }
    
    func videoNode(by appIconNode: SCNNode, position: SCNVector3) -> SCNNode? {
        sceneView.scene.rootNode.childNode(withName: "videoPlaneNode", recursively: true)?.removeFromParentNode()
        guard let appIconNodeName = appIconNode.name else { return nil }
        let videoNode = SKVideoNode(fileNamed: "\(appIconNodeName).mp4")
        videoNode.play()
        
        let skScene = SKScene(size: CGSize(width: 375, height: 667))
        skScene.addChild(videoNode)
        
        videoNode.position = CGPoint(x: skScene.size.width/2, y: skScene.size.height/2)
        videoNode.size = skScene.size
        
        let videoPlane = SCNPlane(width:375*0.0002, height:667*0.0002)
        videoPlane.firstMaterial?.diffuse.contents = skScene
        videoPlane.firstMaterial?.isDoubleSided = true
        
        let videoPlaneNode = SCNNode(geometry: videoPlane)
        videoPlaneNode.eulerAngles.z = .pi
        videoPlaneNode.eulerAngles.x = -.pi/2
        videoPlaneNode.eulerAngles.y = -.pi
        videoPlaneNode.name = "videoPlaneNode"
        videoPlaneNode.position = position
        
        return videoPlaneNode
    }
    
    func viewNode(with size: CGSize, name: String, position: SCNVector3, view: UIView) -> SCNNode{
        let viewPlane = SCNPlane(width: size.width , height: size.height)
        viewPlane.firstMaterial?.diffuse.contents = view
        viewPlane.cornerRadius = 0.01
        
        let viewPlaneNode = SCNNode(geometry: viewPlane)
        viewPlaneNode.eulerAngles.x = -.pi / 2
        viewPlaneNode.position = position
        viewPlaneNode.name = name
        
        return viewPlaneNode
    }
    
    func appIconNode(with size: CGSize, name: String, position: SCNVector3) -> SCNNode {
        let appIconPlane = SCNPlane(width: size.width, height: size.height)
        appIconPlane.firstMaterial?.diffuse.contents = UIImage(named: name)
        appIconPlane.width = size.height
        appIconPlane.height = size.height
        appIconPlane.cornerRadius = 0.005
        
        let appIconPlaneNode = SCNNode(geometry: appIconPlane)
        appIconPlaneNode.name = name
        appIconPlaneNode.eulerAngles.x = -.pi / 2
        appIconPlaneNode.position = position
        
        return appIconPlaneNode
    }
}
