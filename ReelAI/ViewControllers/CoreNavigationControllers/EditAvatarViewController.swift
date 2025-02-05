import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

class EditAvatarViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedImage: UIImage?
    private var completion: ((Bool) -> Void)?
    private var assets: PHFetchResult<PHAsset>?
    private var selectedAssets: Set<String> = []
    
    // MARK: - UI Components
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("All", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        button.layer.cornerRadius = 15
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        cv.register(CameraCell.self, forCellWithReuseIdentifier: "CameraCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let selectMultipleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select multiple", for: .normal)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPhotoLibraryPermission()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        // Add subviews
        view.addSubview(filterButton)
        view.addSubview(collectionView)
        view.addSubview(selectMultipleButton)
        
        // Setup delegates
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Setup constraints
        NSLayoutConstraint.activate([
            filterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: selectMultipleButton.topAnchor),
            
            selectMultipleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectMultipleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // Add targets
        filterButton.addTarget(self, action: #selector(handleFilterTap), for: .touchUpInside)
        selectMultipleButton.addTarget(self, action: #selector(handleSelectMultipleTap), for: .touchUpInside)
    }
    
    // MARK: - Photo Library
    private func checkPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.fetchPhotos()
                }
            }
        }
    }
    
    private func fetchPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: options)
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func handleCancel() {
        dismiss(animated: true) {
            self.completion?(false)
        }
    }
    
    @objc private func handleFilterTap() {
        // TODO: Show filter options
    }
    
    @objc private func handleSelectMultipleTap() {
        // TODO: Toggle multiple selection mode
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        avatarRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error uploading avatar: \(error.localizedDescription)")
                return
            }
            
            avatarRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else { return }
                self.updateUserAvatar(url: downloadURL.absoluteString)
            }
        }
    }
    
    private func updateUserAvatar(url: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "avatar": url
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating user avatar: \(error.localizedDescription)")
                return
            }
            
            self.dismiss(animated: true) {
                self.completion?(true)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension EditAvatarViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (assets?.count ?? 0) + 1 // +1 for camera cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath) as! CameraCell
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        if let asset = assets?[indexPath.item - 1] {
            cell.configure(with: asset)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 2) / 3 // 2 is total spacing between items
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            handleCamera()
            return
        }
        
        guard let asset = assets?[indexPath.item - 1] else { return }
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { [weak self] image, info in
            guard let self = self,
                  let image = image else { return }
            
            self.selectedImage = image
            self.uploadImage(image)
        }
    }
}

// MARK: - PhotoCell
class PhotoCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with asset: PHAsset) {
        let manager = PHImageManager.default()
        manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: nil) { [weak self] image, _ in
            self?.imageView.image = image
        }
    }
}

// MARK: - CameraCell
class CameraCell: UICollectionViewCell {
    private let cameraIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "camera.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .darkGray
        contentView.addSubview(cameraIcon)
        
        NSLayoutConstraint.activate([
            cameraIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 30),
            cameraIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

// MARK: - Camera Handling
extension EditAvatarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func handleCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedImage = image
        uploadImage(image)
    }
} 