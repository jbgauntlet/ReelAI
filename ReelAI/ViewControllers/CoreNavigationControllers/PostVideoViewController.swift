//
//  PostVideoViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/6/25.
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class PostVideoViewController: UIViewController {
    
    // MARK: - Properties
    private let videoURL: URL
    private var compressedVideoURL: URL?
    private var tags: [String] = []
    
    // MARK: - UI Components
    private let videoPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter video title"
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
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
    
    private let tagTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter a tag"
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let addTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Tag", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Tags: "
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Post Reel"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    }
    
    deinit {
        cleanupVideoFiles()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(backButton)
        view.addSubview(headerLabel)
        view.addSubview(titleTextField)
        view.addSubview(captionTextField)
        view.addSubview(tagTextField)
        view.addSubview(addTagButton)
        view.addSubview(tagsLabel)
        view.addSubview(postButton)
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            headerLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            titleTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            captionTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 12),
            captionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captionTextField.heightAnchor.constraint(equalToConstant: 44),
            
            tagTextField.topAnchor.constraint(equalTo: captionTextField.bottomAnchor, constant: 12),
            tagTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tagTextField.trailingAnchor.constraint(equalTo: addTagButton.leadingAnchor, constant: -10),
            tagTextField.heightAnchor.constraint(equalToConstant: 44),
            
            addTagButton.centerYAnchor.constraint(equalTo: tagTextField.centerYAnchor),
            addTagButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addTagButton.widthAnchor.constraint(equalToConstant: 80),
            addTagButton.heightAnchor.constraint(equalToConstant: 30),
            
            tagsLabel.topAnchor.constraint(equalTo: tagTextField.bottomAnchor, constant: 12),
            tagsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            postButton.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 20),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            postButton.heightAnchor.constraint(equalToConstant: 44),
            
            progressLabel.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 12),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        postButton.addTarget(self, action: #selector(handlePost), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        addTagButton.addTarget(self, action: #selector(handleAddTag), for: .touchUpInside)
        
        updateTagsLabel()
    }
    
    // MARK: - Actions
    @objc private func handleAddTag() {
        guard let tag = tagTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tag.isEmpty else { return }
        
        tags.append(tag)
        updateTagsLabel()
        tagTextField.text = ""
    }
    
    private func updateTagsLabel() {
        if tags.isEmpty {
            tagsLabel.text = "Tags: None"
        } else {
            tagsLabel.text = "Tags: " + tags.map { "#\($0)" }.joined(separator: " ")
        }
    }
    
    @objc private func handlePost() {
        compressVideo(videoURL)
    }
    
    @objc private func handleBack() {
        cleanupVideoFiles()
        navigationController?.popViewController(animated: true)
    }
    
    private func compressVideo(_ videoURL: URL) {
        progressLabel.text = "Compressing video..."
        
        let asset = AVAsset(url: videoURL)
        let preset = AVAssetExportPresetMediumQuality
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            progressLabel.text = "Error creating export session"
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let compressedURL = documentsPath.appendingPathComponent("compressed_video.mp4")
        
        // Remove existing file
        try? FileManager.default.removeItem(at: compressedURL)
        
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch exportSession.status {
                case .completed:
                    self.compressedVideoURL = compressedURL
                    self.uploadToFirebase(compressedURL)
                case .failed:
                    self.progressLabel.text = "Compression failed: \(exportSession.error?.localizedDescription ?? "")"
                case .cancelled:
                    self.progressLabel.text = "Compression cancelled"
                default:
                    break
                }
            }
        }
    }
    
    private func uploadToFirebase(_ videoURL: URL) {
        guard let userId = Auth.auth().currentUser?.uid else {
            progressLabel.text = "Please sign in to upload"
            return
        }
        
        progressLabel.text = "Uploading video..."
        print("📤 Starting video upload process")
        
        let videoId = UUID().uuidString
        let storageRef = Storage.storage().reference()
        let videoRef = storageRef.child("videos/\(userId)/\(videoId).mp4")
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        print("🎬 Uploading video with ID: \(videoId)")
        let uploadTask = videoRef.putFile(from: videoURL, metadata: metadata)
        
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let self = self else { return }
            let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
            self.progressLabel.text = "Upload progress: \(Int(percentComplete * 100))%"
            print("📊 Upload progress: \(Int(percentComplete * 100))%")
        }
        
        uploadTask.observe(.success) { [weak self] _ in
            guard let self = self else { return }
            print("✅ Video upload to Storage successful")
            
            videoRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Error getting download URL: \(error.localizedDescription)")
                    self.progressLabel.text = "Error getting download URL: \(error.localizedDescription)"
                    return
                }
                
                guard let downloadURL = url else {
                    print("❌ Download URL is nil")
                    self.progressLabel.text = "Error: couldn't get download URL"
                    return
                }
                
                print("🔗 Got download URL: \(downloadURL.absoluteString)")
                self.saveToFirestore(videoId: videoId, videoUrl: downloadURL.absoluteString)
            }
        }
        
        uploadTask.observe(.failure) { [weak self] snapshot in
            print("❌ Upload failed: \(snapshot.error?.localizedDescription ?? "Unknown error")")
            self?.progressLabel.text = "Upload failed: \(snapshot.error?.localizedDescription ?? "")"
        }
    }
    
    private func saveToFirestore(videoId: String, videoUrl: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("💾 Saving video metadata to Firestore...")
        print("📝 Video ID: \(videoId)")
        print("👤 Creator ID: \(userId)")
        print("🔗 Storage Path: \(videoUrl)")
        
        let db = Firestore.firestore()
        let videoData: [String: Any] = [
            "storage_path": videoUrl,
            "creator_id": userId,
            "title": titleTextField.text ?? "",
            "caption": captionTextField.text ?? "",
            "tags": tags,
            
            // Counters
            "views_count": 0,
            "likes_count": 0,
            "comments_count": 0,
            "bookmarks_count": 0,
            
            // Metadata
            "created_at": FieldValue.serverTimestamp(),
            "updated_at": FieldValue.serverTimestamp()
        ]
        
        db.collection("videos").document(videoId).setData(videoData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Firestore save error: \(error.localizedDescription)")
                self.progressLabel.text = "Error saving to Firestore: \(error.localizedDescription)"
            } else {
                print("✅ Successfully saved video metadata to Firestore")
                print("📊 Video data: \(videoData)")
                self.progressLabel.text = "Upload complete!"
                self.postButton.isEnabled = false
                self.postButton.alpha = 0.5
                
                // Clean up video files and navigate back
                self.cleanupVideoFiles()
                
                // Navigate back to the main feed after successful upload
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    private func cleanupVideoFiles() {
        // Clean up original video if it's in the app's directory
        if videoURL.path.contains(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path) {
            try? FileManager.default.removeItem(at: videoURL)
        }
        
        // Clean up compressed video
        if let compressedURL = compressedVideoURL {
            try? FileManager.default.removeItem(at: compressedURL)
        }
    }
}
