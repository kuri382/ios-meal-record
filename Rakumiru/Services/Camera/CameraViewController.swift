import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var metadataOutput: AVCaptureMetadataOutput!
    var didCapturePhoto: ((UIImage) -> Void)?
    var delegate: AVCapturePhotoCaptureDelegate?
    private var canCapturePhoto = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if (captureSession.canAddOutput(photoOutput)) {
            captureSession.addOutput(photoOutput)
        } else {
            return
        }

        metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate!)
        canCapturePhoto = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.canCapturePhoto = true
        }
    }

    // AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !canCapturePhoto { return }

        for metadata in metadataObjects {
            if metadata.type == .qr, let readableObject = metadata as? AVMetadataMachineReadableCodeObject, let stringValue = readableObject.stringValue {
                if let data = stringValue.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    do {
                        let userQRCode = try decoder.decode(UserQRCode.self, from: data)
                        NotificationCenter.default.post(name: NSNotification.Name("QRCodeDetected"), object: nil, userInfo: ["userId": userQRCode.user_id])
                        print("Decoded User ID: \(userQRCode.user_id)")
                    } catch {
                        print("Failed to decode QR code data: \(error)")
                    }
                }
                capturePhoto()
                break
            }
        }
    }
}
