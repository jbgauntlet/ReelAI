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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    func configure(with video: Video) {
        // Get video thumbnail
        let storage = Storage.storage()
        let thumbnailPath = "thumbnails/\(video.id).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        
        // First try to get thumbnail
        thumbnailRef.getData(maxSize: 1 * 1024 * 1024) { [weak self] data, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.thumbnailImageView.image = image
                }
            } else {
                // If no thumbnail, try to generate one from the video
                self?.generateThumbnail(from: video.storagePath)
            }
        }
        
        // Set views count
        viewsLabel.text = "\(video.viewsCount) views"
    }
    
    private func generateThumbnail(from videoUrl: String) {
        guard let url = URL(string: videoUrl) else { return }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Try to get thumbnail at 0.0 seconds
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let thumbnail = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self?.thumbnailImageView.image = thumbnail
                }
                
                // Save thumbnail for future use
                self?.saveThumbnail(thumbnail, for: videoUrl)
            }
        }
    }
    
    private func saveThumbnail(_ image: UIImage, for videoUrl: String) {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        
        let storage = Storage.storage()
        let thumbnailPath = "thumbnails/\(videoUrl.hashValue).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        
        thumbnailRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("Error saving thumbnail: \(error)")
            }
        }
    }
}
