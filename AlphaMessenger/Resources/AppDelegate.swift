//
//  AppDelegate.swift
//  AlphaMessenger
//
//  Created by developer on 3.05.21.
//

import UIKit
import Firebase
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

//    import UIKit
//    import Firebase
//
//    @UIApplicationMain
//    class AppDelegate: UIResponder, UIApplicationDelegate {
//
//      var window: UIWindow?
//
//      func application(_ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions:
//          [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        FirebaseApp.configure()
//        return true
//      }
//    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Error sign in with Google: \(error)")
            }
            return
        }
        
//        print("Did sign in with Google: \(user)")
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName else {
                return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email) { exists in
            if !exists {
                
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAddress: email)
                //insert in database
                DatabaseManager.shared.insertUser(with: chatUser) { success in
                    if success {
                        // upload image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { data, response, error in
                                guard let data = data else {
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data,
                                                                           filename: fileName) { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage Manager error: \(error)")
                                    }
                                }
                            }.resume()
                            
                        }
                    }
                }
            }
        }
        
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of Google User.")
            return
        }
          let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                         accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
            guard authResult != nil, error == nil else {
                print("Failed to log in with Google credentials")
                return
            }
            print("Succesfully signed in with Google credentials")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
}
    
    
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected.")
    }
}

