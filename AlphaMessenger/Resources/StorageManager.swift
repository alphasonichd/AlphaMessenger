//
//  StorageManager.swift
//  AlphaMessenger
//
//  Created by developer on 13.05.21.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    // images/alexandersnitko-gmail-com_profile_picture.png
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads pictures to firebase and returns completion with urlstring to download
    public func uploadProfilePicture(with data: Data,
                                     filename: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(filename)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
}
