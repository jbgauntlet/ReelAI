

import Foundation
import FirebaseAuth
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let auth = Auth.auth()
    private let storage = Storage.storage()
    
    private init() {
        // Set up custom URL scheme handling
        if let bundleId = Bundle.main.bundleIdentifier {
            Auth.auth().setCustomURLScheme(bundleId)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication result"])))
                return
            }
            
            // Convert Firebase User to your app's User model
            let user = User(id: result.user.uid, email: result.user.email ?? "", username: "", refreshToken: "", accessToken: "")
            completion(.success(user))
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication result"])))
                return
            }
            
            // Convert Firebase User to your app's User model
            let user = User(id: result.user.uid, email: result.user.email ?? "", username: "", refreshToken: "", accessToken: "")
            completion(.success(user))
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Storage Methods
    
    func uploadFile(data: Data, path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = storage.reference().child(path)
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    func downloadFile(path: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let storageRef = storage.reference().child(path)
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            completion(.success(data))
        }
    }
    
    func deleteFile(path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child(path)
        
        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
} 