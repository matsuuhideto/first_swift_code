//
//  ViewController.swift
//  delaycamera
//
//  Created by hideto matsuu on 10/8/24.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoQueue = DispatchQueue(label: "videoQueue")
    
    var bufferTime: TimeInterval = 5 {
        didSet {
            adjustBufferSize()
        }
    }
    var buffer = [CMSampleBuffer]()
    
    // 現在使用しているカメラ（デフォルトはバックカメラ）
    var currentCamera: AVCaptureDevice.Position = .back {
        didSet {
            switchCamera()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        configureCamera(position: currentCamera)
    }
    
    func configureCamera(position: AVCaptureDevice.Position) {
        captureSession.beginConfiguration()
        
        // 既存の入力を削除
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            fatalError("No camera available")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            fatalError("Error setting up camera input: \(error)")
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    func switchCamera() {
        captureSession.stopRunning()
        configureCamera(position: currentCamera)
    }

    func adjustBufferSize() {
        while buffer.count > Int(bufferTime * 30) { // Assuming 30 fps
            buffer.removeFirst()
        }
    }
    
    func appendBuffer(_ sampleBuffer: CMSampleBuffer) {
        if buffer.count >= Int(bufferTime * 30) {
            buffer.removeFirst()
        }
        buffer.append(sampleBuffer)
    }
    
    func getBufferedVideo() -> [CMSampleBuffer] {
        return buffer
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        bufferTime = TimeInterval(sender.value)
    }
    
    // カメラを切り替えるUIのサンプル
    @IBAction func cameraSwitchToggled(_ sender: UISwitch) {
        currentCamera = sender.isOn ? .front : .back
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        appendBuffer(sampleBuffer)
    }
}

