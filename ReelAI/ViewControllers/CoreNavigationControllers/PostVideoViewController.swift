//
//  PostVideoViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/6/25.
//

import UIKit
import AVFoundation

class PostVideoViewController: UIViewController {
    
    // MARK: - Properties
    private let videoURL: URL
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // MARK: - UI Components
    private let videoPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captionTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Add a caption..."
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPreviewView.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "New Post"
        
        view.addSubview(videoPreviewView)
        view.addSubview(captionTextField)
        view.addSubview(postButton)
        
        NSLayoutConstraint.activate([
            videoPreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPreviewView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 16/9),
            
            captionTextField.topAnchor.constraint(equalTo: videoPreviewView.bottomAnchor, constant: 20),
            captionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captionTextField.heightAnchor.constraint(equalToConstant: 44),
            
            postButton.topAnchor.constraint(equalTo: captionTextField.bottomAnchor, constant: 20),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            postButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        postButton.addTarget(self, action: #selector(handlePost), for: .touchUpInside)
    }
    
    private func setupVideo() {
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            videoPreviewView.layer.addSublayer(playerLayer)
        }
        
        // Loop video playback
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                            object: player?.currentItem,
                                            queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
    }
    
    // MARK: - Actions
    @objc private func handlePost() {
        // TODO: Implement video upload with caption
        let caption = captionTextField.text ?? ""
        print("Posting video with caption: \(caption)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
