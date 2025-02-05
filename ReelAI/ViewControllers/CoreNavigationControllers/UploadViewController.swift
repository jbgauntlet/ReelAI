import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import MobileCoreServices

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let selectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select Video", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Upload", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "No video selected"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter video title"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .white
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let captionTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter video caption"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .white
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let tagTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter a tag"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .white
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let addTagButton: UIButton = {
        let button = UIButton()
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
    
    private var selectedVideoURL: URL?
    private var compressedVideoURL: URL?
    private var tags: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F6F7F9")
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(selectButton)
        view.addSubview(titleTextField)
        view.addSubview(captionTextField)
        view.addSubview(tagTextField)
        view.addSubview(addTagButton)
        view.addSubview(tagsLabel)
        view.addSubview(uploadButton)
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectButton.widthAnchor.constraint(equalToConstant: 200),
            selectButton.heightAnchor.constraint(equalToConstant: 50),
            
            titleTextField.topAnchor.constraint(equalTo: selectButton.bottomAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            captionTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            captionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captionTextField.heightAnchor.constraint(equalToConstant: 40),
            
            tagTextField.topAnchor.constraint(equalTo: captionTextField.bottomAnchor, constant: 20),
            tagTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagTextField.trailingAnchor.constraint(equalTo: addTagButton.leadingAnchor, constant: -10),
            tagTextField.heightAnchor.constraint(equalToConstant: 40),
            
            addTagButton.centerYAnchor.constraint(equalTo: tagTextField.centerYAnchor),
            addTagButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTagButton.widthAnchor.constraint(equalToConstant: 80),
            addTagButton.heightAnchor.constraint(equalToConstant: 30),
            
            tagsLabel.topAnchor.constraint(equalTo: tagTextField.bottomAnchor, constant: 20),
            tagsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            uploadButton.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 30),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 200),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            progressLabel.widthAnchor.constraint(equalToConstant: 300),
            progressLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        selectButton.addTarget(self, action: #selector(handleSelectVideo), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(handleUploadVideo), for: .touchUpInside)
        addTagButton.addTarget(self, action: #selector(handleAddTag), for: .touchUpInside)
    }
    
    @objc private func handleSelectVideo() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = ["public.movie"]
        picker.sourceType = .photoLibrary
        picker.videoQuality = .typeHigh
        present(picker, animated: true)
    }
    
    @objc private func handleUploadVideo() {
        guard let videoURL = selectedVideoURL else { return }
        compressVideo(videoURL)
    }
    
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
                self.uploadButton.isEnabled = false
                self.uploadButton.alpha = 0.5
                self.selectedVideoURL = nil
                self.compressedVideoURL = nil
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        guard let videoURL = info[.mediaURL] as? URL else {
            progressLabel.text = "Error: Could not get video URL"
            return
        }
        
        selectedVideoURL = videoURL
        uploadButton.isEnabled = true
        uploadButton.alpha = 1.0
        progressLabel.text = "Video selected - Ready to upload"
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
