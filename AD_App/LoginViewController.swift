//
//  LoginViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import KeychainSwift

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var staffIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        staffIDTextField.delegate = self
        passwordTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == staffIDTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
            loginButtonTapped(textField)
        }
        return true
    }

    func displayMessage(userMessage:String) -> Void {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Prompt", message: userMessage, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                print("OK button pressed")
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        print("Login Button Tapped")
        
        let staffID = staffIDTextField.text
        let password = passwordTextField.text
        
        if (staffID?.isEmpty)! || (password?.isEmpty)! {
            displayMessage(userMessage: "One of the required fields is missing.")
            return
        }
        
        if reachability.connection != .none {
        
            let myActivityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            myActivityIndicator.center = view.center
            myActivityIndicator.hidesWhenStopped = false
            myActivityIndicator.startAnimating()
            view.addSubview(myActivityIndicator)
            
            let loginUrl = URL(string: "\(v_host)/api/auth/signin")
            var request = URLRequest(url: loginUrl!)
            
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let postString = ["username": staffID!, "password": password!] as [String: String]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                displayMessage(userMessage: "Something went wrong...")
            }
            
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                
                if error != nil
                {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")
                    print("error=\(String(describing: error))")
                    return
                }

                do
                {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary

                    if let parseJSON = json
                    {
                        let status = parseJSON["success"] as? Bool

                        if status!
                        {
                            let accessToken = parseJSON["token"] as? String
                            print("Access Token: \(String(describing: accessToken!))")

                            let keychain = KeychainSwift()
                            keychain.set(accessToken!, forKey: "accessToken", withAccess: .accessibleAlways)
                            
                            if keychain.lastResultCode != noErr {
                                print("accessToken save result: \(keychain.lastResultCode)")
                            }

                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            DispatchQueue.main.async
                            {
                                UIApplication.shared.registerForRemoteNotifications()
                                let homePage = self.storyboard?.instantiateViewController(withIdentifier: "TabBarViewController") as! TabBarViewController
                                let appDelegate = UIApplication.shared.delegate
                                appDelegate?.window??.rootViewController = homePage
                            }

                        } else {
                            let msg = parseJSON["msg"] as? String
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            self.displayMessage(userMessage: msg!)
                            return
                        }
                    } else {
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")

                    }
                } catch {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)

                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")
                    print(error)
                }
            }
            task.resume()
        } else {
            displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
