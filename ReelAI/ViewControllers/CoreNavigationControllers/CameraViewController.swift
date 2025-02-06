import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var isRecording = false
    private var recordedVideoURL: URL?
    
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
    
    private let recordingIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.layer.cornerRadius = 4
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Rose color
        button.tintColor = .white
        button.layer.cornerRadius = 22 // Rounded corners
        button.isHidden = true
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
        view.addSubview(recordingIndicator)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            recordingIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            recordingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingIndicator.widthAnchor.constraint(equalToConstant: 8),
            recordingIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            flipCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flipCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flipCameraButton.widthAnchor.constraint(equalToConstant: 44),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 44),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.widthAnchor.constraint(equalToConstant: 60),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        captureButton.addTarget(self, action: #selector(handleCapture), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(handleFlipCamera), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
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
        
        // Add video input
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Add movie file output
        movieFileOutput = AVCaptureMovieFileOutput()
        if let movieFileOutput = movieFileOutput,
           captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
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
        guard let movieFileOutput = movieFileOutput else { return }
        
        if !isRecording {
            // Start recording
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
            movieFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
            
            // Update UI for recording state
            UIView.animate(withDuration: 0.3) {
                self.captureButton.backgroundColor = .red
                self.recordingIndicator.isHidden = false
                self.nextButton.isHidden = true
            }
        } else {
            // Stop recording
            movieFileOutput.stopRecording()
            
            // Update UI for stopped state
            UIView.animate(withDuration: 0.3) {
                self.captureButton.backgroundColor = .white
                self.recordingIndicator.isHidden = true
            }
        }
        
        isRecording = !isRecording
    }
    
    @objc private func handleFlipCamera() {
        switchCamera()
    }
    
    @objc private func handleClose() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleNext() {
        guard let videoURL = recordedVideoURL else { return }
        let postVideoVC = PostVideoViewController(videoURL: videoURL)
        navigationController?.pushViewController(postVideoVC, animated: true)
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

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            return
        }
        
        // Store the recorded video URL
        recordedVideoURL = outputFileURL
        
        // Show the next button and hide flip camera button
        DispatchQueue.main.async {
            self.nextButton.isHidden = false
            self.flipCameraButton.isHidden = true
        }
        
        print("Video recorded successfully at: \(outputFileURL)")
    }
}
