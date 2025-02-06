import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    // MARK: - UI Components
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let flipCameraButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        button.setImage(UIImage(systemName: "camera.rotate", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Session cleanup will be handled in deinit
    }
    
    deinit {
        captureSession?.stopRunning()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(previewView)
        view.addSubview(captureButton)
        view.addSubview(flipCameraButton)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            flipCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flipCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flipCameraButton.widthAnchor.constraint(equalToConstant: 44),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 44),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        captureButton.addTarget(self, action: #selector(handleCapture), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(handleFlipCamera), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied:
            alertCameraAccessNeeded()
        case .restricted:
            alertCameraAccessRestricted()
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        
        if let videoPreviewLayer = videoPreviewLayer {
            previewView.layer.addSublayer(videoPreviewLayer)
        }
    }
    
    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCaptureSession() {
        captureSession?.stopRunning()
    }
    
    private func switchCamera() {
        guard let session = captureSession else { return }
        
        // Remove existing input
        session.beginConfiguration()
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Switch camera position
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        // Add new input
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - Actions
    @objc private func handleCapture() {
        // TODO: Implement video recording
        print("Capture button tapped")
    }
    
    @objc private func handleFlipCamera() {
        switchCamera()
    }
    
    @objc private func handleClose() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Alerts
    private func alertCameraAccessNeeded() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this feature",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func alertCameraAccessRestricted() {
        let alert = UIAlertController(
            title: "Camera Access Restricted",
            message: "Camera access is restricted and cannot be enabled for this app",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}
