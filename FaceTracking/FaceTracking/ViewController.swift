//
//  ViewController.swift
//  FaceTracking
//
//  Created by 박세은 on 2018. 11. 26..
//  Copyright © 2018년 박세은. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var session:ARSession!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var answerLbl: UILabel!
    @IBOutlet weak var scoreLbl: UILabel!
   
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var finishView: UIView!
    @IBOutlet weak var finalScoreLbl: UILabel!
    
    @IBOutlet weak var startBtn: UIButton!
    
    // 카운트다운
    var countdownTimer: Timer!
    var totalTime = 30

    // 정답
    var faceStatuses: [faceStatus] = [.mouthSmileLeft, .jawOpen, .eyeBlinkLeft, .jawOpen,  .sleep,  .browDown, .mouthSmileLeft, .jawOpen , .browUp, .tongueOut, .sleep, .browUp, .eyeBlinkLeft, .tongueOut, .browDown, .jawOpen,.mouthSmileLeft, .jawOpen, .eyeBlinkLeft, .jawOpen,  .sleep,  .browDown, .mouthSmileLeft, .jawOpen , .browUp, .tongueOut, .sleep, .browUp, .eyeBlinkLeft, .tongueOut, .browDown, .jawOpen ]
    
    // 정답 배열의 index
    var index = 0 {
        didSet {
            scoreLbl.text = "+\(index)"
            resetAnswerLbl()
        }
    }
    // 시작 여부
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        session = ARSession()
        sceneView.session = self.session
        session.delegate = self
        
        answerLbl.text = ""
        for i in 0...faceStatuses.count-1 {
            if let originText = answerLbl.text {
                answerLbl.text = originText + faceStatuses[i].rawValue + " "
            }
        }
        
        index = 0
        finishView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        guard ARFaceTrackingConfiguration.isSupported else {
            print("required over iPhone X")
            return
        }
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    func startTimer() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        timerLbl.text = "\(timeFormatted(totalTime))"
        
        if totalTime != 0 {
            totalTime -= 1
        } else {
            endTimer()
        }
    }
    
    func endTimer() {
        playing = false
        countdownTimer.invalidate()
        startBtn.isHidden = false
        finishView.isHidden = false
        finalScoreLbl.text = "\(index)"
    }
    
    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @IBAction func clickedStart(_ sender: UIButton) {
        index = 0
        totalTime = 30
        startTimer()
        playing = true
        startBtn.isHidden = true
        finishView.isHidden = true
    }
    
    // 정답 맞추면 answer label을 변경
    func resetAnswerLbl() {
        answerLbl.text = ""
        if index == faceStatuses.count {
            clear()
            return
        }
        for i in index...faceStatuses.count-1 {
            if let originText = answerLbl.text {
                answerLbl.text = originText + faceStatuses[i].rawValue + " "
            }
        }
    }
    
    func clear() {
        answerLbl.text = "CLEAR!!!"
        endTimer()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        }else {
            return .all
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if !playing {return}
        if let faceAnchor = anchors.first as? ARFaceAnchor {
            print("face Anchor 발견")
            if index == faceStatuses.count {
                self.session.pause()
                return
            }
            
            if faceStatuses[index] == update(faceAnchor: faceAnchor){
                 index = index + 1
            }
        }
    }
    
    func update(faceAnchor: ARFaceAnchor) -> faceStatus? {
        
        // blendShapes : 얼굴의 움직임(이목구비, 표정 등등)과 관련된 dictionary
        // key : ARFaceAnchor.BlendShapeLocation는 이목구비 등등의 움직임에 대한 계수
        // 그에 대한 움직임의 수치값을 value로 가지고 있음 (아주 많은 정보가 담겨있음)
        var blendShapes:[ARFaceAnchor.BlendShapeLocation:Any] = faceAnchor.blendShapes
        
        // 우리가 필요한 BlendShapeLocation는 browInnerUp!!
        // 두 눈썹 안쪽 부분의 상향 이동에 대한 정보를 0.0 ~ 1.0의 수치로 가지고 있음
        if let browInnerUp = blendShapes[.browInnerUp] as? Float{
            // 눈썹이 올라가면
            if browInnerUp > 0.85 {
                print("눈썹 올라감")
                return .browUp
            }
        }
    
        if let browInnerUp = blendShapes[.browInnerUp] as? Float, let jawOpen = blendShapes[.jawOpen] as? Float {
            if jawOpen > 0.8 && browInnerUp < 0.1 {
                print("눈썹 내려감")
                return .browDown
            }
        }
        
        // 혀 내민 수준 : 1.0이 완전 내밀었을 때
        if let tongueOut = blendShapes[.tongueOut] as? Float{
            if tongueOut > 0.99 {
                print("메롱")
                return .tongueOut
            }
        }
        
        // 왼쪽 눈 감은 정도 0.0: 떴음, 1.0: 완전히 감음
        // 오른쪽 눈 감은 정도 0.0: 떴음, 1.0: 완전히 감음
        if let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float, let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float  {
            if eyeBlinkLeft > 0.99 && eyeBlinkRight > 0.99 {
                print("눈 감음")
                return .sleep
            }
            if eyeBlinkLeft > 0.95 && eyeBlinkRight < 0.2  {
                print("오른쪽 눈 윙크")
                return .eyeBlinkLeft
            }
        }
        
        
//        if let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float {
//            if eyeBlinkLeft > 0.95  {
//                print("오른쪽 눈 윙크")
//                return .eyeBlinkLeft
//            }
//        }
        
        if let mouthSmileLeft = blendShapes[.mouthLeft] as? Float {
            if mouthSmileLeft > 0.3 {
                print("오른쪽 입꼬리 피식")
                return .mouthSmileLeft
            }
        }
        if let jawOpen = blendShapes[.jawOpen] as? Float {
            if jawOpen > 0.95 {
                print("입 크게 벌리기")
                return .jawOpen
            }
        }
        
        
        return nil
    }
}
