//
//  ProfileVideoThumbnailCell.swift
//  ReelAI
//
//  Created by GauntletAI on 2/4/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

class ProfileVideoThumbnailCell: UICollectionViewCell {
    // MARK: - Properties
    private var currentVideoId: String?
    private var downloadTask: StorageDownloadTask?
    private var thumbnailGenerationWorkItem: DispatchWorkItem?
    
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let viewsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
        layer.locations = [0.5, 1.0]
        return layer
    }()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanup()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup & Layout
    private func setupUI() {
        contentView.layer.addSublayer(gradientLayer)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(viewsLabel)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            viewsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            viewsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        // Cancel any pending downloads
        downloadTask?.cancel()
        downloadTask = nil
        
        // Cancel any pending thumbnail generation
        thumbnailGenerationWorkItem?.cancel()
        thumbnailGenerationWorkItem = nil
        
        // Clear current video ID
        currentVideoId = nil
        thumbnailImageView.image = nil
    }
    
    // MARK: - Configuration
    func configure(with video: Video) {
        // Clean up any previous state
        cleanup()
        
        // Set current video ID
        currentVideoId = video.id
        
        // Set views count
        viewsLabel.text = "\(video.viewsCount) views"
        
        // Get video thumbnail using only video ID
        let storage = Storage.storage()
        let thumbnailPath = "thumbnails/\(video.id).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        
        // First try to get thumbnail
        downloadTask = thumbnailRef.getData(maxSize: 1 * 1024 * 1024) { [weak self] data, error in
            guard let self = self, self.currentVideoId == video.id else { return }
            
            if let data = data {
                // Process image on background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            // Verify we're still showing the same video
                            if self.currentVideoId == video.id {
                                self.thumbnailImageView.image = image
                            }
                        }
                    } else {
                        // If thumbnail loading fails, try to generate one from the video
                        self.generateThumbnail(from: video.storagePath, for: video)
                    }
                }
            } else {
                // If no thumbnail exists, try to generate one from the video
                self.generateThumbnail(from: video.storagePath, for: video)
            }
        }
    }
    
    private func generateThumbnail(from videoUrl: String, for video: Video) {
        guard let url = URL(string: videoUrl) else { return }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Create a work item for thumbnail generation
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentVideoId == video.id else { return }
            
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, _ in
                guard let self = self, self.currentVideoId == video.id else { return }
                
                if let cgImage = cgImage {
                    let thumbnail = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        // Final verification before setting the image
                        if self.currentVideoId == video.id {
                            self.thumbnailImageView.image = thumbnail
                            // Save thumbnail for future use
                            self.saveThumbnail(thumbnail, for: video)
                        }
                    }
                }
            }
        }
        
        // Store the work item and execute it
        thumbnailGenerationWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    
    private func saveThumbnail(_ image: UIImage, for video: Video) {
        // Calculate size that maintains aspect ratio
        let maxDimension: CGFloat = 720  // Increased for better quality
        let size = image.size
        
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let scale = min(widthRatio, heightRatio)  // Use the smaller scale to fit within bounds
        
        // Only scale down, never up
        let finalScale = scale < 1.0 ? scale : 1.0
        
        let newSize = CGSize(
            width: size.width * finalScale,
            height: size.height * finalScale
        )
        
        // Create a properly scaled version of the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw maintaining aspect ratio
        let rect = CGRect(origin: .zero, size: newSize)
        image.draw(in: rect)
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let data = resizedImage.jpegData(compressionQuality: 1.0) else {
            print("❌ Failed to create thumbnail data")
            return
        }
        
        // Use simplified path structure: thumbnails/{videoId}.jpg
        let storage = Storage.storage()
        let thumbnailPath = "thumbnails/\(video.id).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        
        // Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("📝 Attempting to save thumbnail:")
        print("   Path: \(thumbnailPath)")
        print("   Original Size: \(image.size)")
        print("   New Size: \(newSize)")
        print("   Data Size: \(data.count) bytes")
        print("   Content Type: \(metadata.contentType ?? "unknown")")
        
        thumbnailRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Error saving thumbnail:")
                print("   Error: \(error.localizedDescription)")
                print("   Details: \(error)")
            } else {
                print("✅ Successfully saved thumbnail")
                print("   Path: \(thumbnailPath)")
                if let metadata = metadata {
                    print("   Size: \(metadata.size) bytes")
                    print("   Content Type: \(metadata.contentType ?? "unknown")")
                }
            }
        }
    }
}
