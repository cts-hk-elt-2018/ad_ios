//
//  SettingViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import KeychainSwift
import SwiftyJSON

class SettingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var enableScreenControlSwitch: UISwitch!
    @IBOutlet weak var pagePicker: UIPickerView!
    @IBOutlet weak var soundPicker: UIPickerView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var pagePickerId: [String] = [String]()
    var pagePickerData: [String] = [String]()
    var soundPickerId: [String] = [String]()
    var soundPickerData: [String] = [String]()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Do any additional setup after loading the view, typically from a nib.
        pagePicker.delegate = self
        pagePicker.dataSource = self
        soundPicker.delegate = self
        soundPicker.dataSource = self
        
        soundPickerData = ["--- Sound Effect ---"]
        soundPickerId = ["0"]
        
        getPageList()
        getSoundList()
    }
    
    @IBAction func previousButtonTapped(_ sender: Any) {
        let currentRow = self.pagePicker.selectedRow(inComponent: 0)
        if currentRow > 1 {
            self.pagePicker.selectRow(currentRow - 1, inComponent: 0, animated: true)
            self.showButtonTapped(sender)
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        let currentRow = self.pagePicker.selectedRow(inComponent: 0)
        if currentRow < pagePickerData.count - 1 {
            self.pagePicker.selectRow(currentRow + 1, inComponent: 0, animated: true)
            self.showButtonTapped(sender)
        }
    }
    

    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    @IBAction func showButtonTapped(_ sender: Any) {
        let currentRow = self.pagePicker.selectedRow(inComponent: 0)
        if currentRow > 0 && currentRow < pagePickerId.count {
            let pageId = pagePickerId[currentRow]
            if reachability.connection != .none {
                let myActivityIndicator = UIActivityIndicatorView(style: .whiteLarge)
                myActivityIndicator.center = view.center
                myActivityIndicator.hidesWhenStopped = false
                myActivityIndicator.startAnimating()
                view.addSubview(myActivityIndicator)
                
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/page/id/\(pageId)")
                
                var request = URLRequest(url: url!)
                
                request.httpMethod = "GET"
                request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "content-type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                    if error != nil
                    {
                        DispatchQueue.main.async
                            {
                            self.showButton.isEnabled = true
                            self.nextButton.isEnabled = true
                            self.previousButton.isEnabled = true
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                            print("error=\(String(describing: error))")
                        }
                        return
                    }
                    guard let data = data else {
                        DispatchQueue.main.async
                            {
                            self.showButton.isEnabled = true
                            self.nextButton.isEnabled = true
                            self.previousButton.isEnabled = true
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                        }
                        return
                    }
                    do
                    {
                        let json = try JSON(data: data)
                        
                        if json["success"].bool! {
                            DispatchQueue.main.async
                                {
                                self.getPageList()
                                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                                self.showButton.isEnabled = true
                                self.nextButton.isEnabled = true
                                self.previousButton.isEnabled = true
                            }
                        } else {
                            let msg = json["msg"].stringValue
                            DispatchQueue.main.async
                                {
                                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                                    self.displayMessage(userMessage: msg)
                                    self.showButton.isEnabled = true
                                    self.nextButton.isEnabled = true
                                    self.previousButton.isEnabled = true
                            }
                            return
                        }
                        
                    } catch {
                        DispatchQueue.main.async
                            {
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            self.showButton.isEnabled = true
                            self.nextButton.isEnabled = true
                            self.previousButton.isEnabled = true
                            self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                        }
                        print("error=\(String(describing: error))")
                    }
                }
                task.resume()
            } else {
                self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
            }
        }
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        let currentRow = self.soundPicker.selectedRow(inComponent: 0)
        if currentRow > 0 {
            let soundId = soundPickerId[currentRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/sound/\(soundId)")
                
                var request = URLRequest(url: url!)
                
                request.httpMethod = "GET"
                request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "content-type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                    if error != nil
                    {
                        self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                        print("error=\(String(describing: error))")
                        return
                    }
                    guard let data = data else {
                        self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                        return
                    }
                    do
                    {
                        let json = try JSON(data: data)
                        
                        if !json["success"].bool! {
                            let msg = json["msg"].stringValue
                            DispatchQueue.main.async
                                {
                                    self.displayMessage(userMessage: msg)
                            }
                            return
                        }
                        
                    } catch {
                        self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                        print("error=\(String(describing: error))")
                    }
                }
                task.resume()
            } else {
                self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
            }
        }
    }
    
    @IBAction func enableScreenControlChanged(_ sender: Any) {
        if enableScreenControlSwitch.isOn {
            self.tabBarController!.tabBar.items![1].isEnabled = true
            self.tabBarController!.tabBar.items![2].isEnabled = true
            self.tabBarController!.tabBar.items![3].isEnabled = true
            self.pagePicker.isUserInteractionEnabled = true
            self.pagePicker.alpha = 1
            self.showButton.isEnabled = true
            self.previousButton.isEnabled = true
            self.nextButton.isEnabled = true
            self.soundPicker.isUserInteractionEnabled = true
            self.soundPicker.alpha = 1
            self.playButton.isEnabled = true
        } else {
            self.tabBarController!.tabBar.items![1].isEnabled = false
            self.tabBarController!.tabBar.items![2].isEnabled = false
            self.tabBarController!.tabBar.items![3].isEnabled = false
            self.pagePicker.isUserInteractionEnabled = false
            self.pagePicker.alpha = 0.6
            self.showButton.isEnabled = false
            self.previousButton.isEnabled = false
            self.nextButton.isEnabled = false
            self.soundPicker.isUserInteractionEnabled = false
            self.soundPicker.alpha = 0.6
            self.playButton.isEnabled = false
        }
        
    }
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let keychain = KeychainSwift()
        keychain.clear()
        
        let loginPage = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = loginPage
    }
    
    func displayMessage(userMessage:String) -> Void {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Prompt", message: userMessage, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func getPageList() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            let url = URL(string: "\(v_host)/api/page/currentPage")
            var request = URLRequest(url: url!)
            
            request.httpMethod = "GET"
            request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil
                {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    print("error=\(String(describing: error))")
                    return
                }
                guard let data = data else {
                    self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                    return
                }
                do
                {
                    let json = try JSON(data: data)
                    
                    if json["success"].bool ?? false {
                        
                        let currentPageId = json["result"]["value"].intValue
         
                        let url = URL(string: "\(v_host)/api/page/list")
                        
                        var request = URLRequest(url: url!)
                        
                        request.httpMethod = "GET"
                        request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                        request.addValue("application/json", forHTTPHeaderField: "content-type")
                        request.addValue("application/json", forHTTPHeaderField: "Accept")
                        
                        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                            if error != nil
                            {
                                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                                print("error=\(String(describing: error))")
                                return
                            }
                            guard let data = data else {
                                self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                                return
                            }
                            do
                            {
                                let json = try JSON(data: data)
                                
                                if json["success"].bool ?? false {
                                    let arrayNames = json["result"].arrayValue.map({$0["id"].intValue == currentPageId ? "(Current) " + $0["displayName"].stringValue : $0["displayName"].stringValue})
                                    let arrayIds = json["result"].arrayValue.map({$0["id"].stringValue})
                                    DispatchQueue.main.async {
                                        self.pagePickerData = ["--- Page ---"] + arrayNames
                                        self.pagePickerId = ["0"] + arrayIds
                                        self.pagePicker.reloadAllComponents()
                                        var i = self.pagePickerId.firstIndex(where: { $0 == String(currentPageId) })
                                        if (i ?? 0 > self.pagePickerId.count - 1 || i ?? 0 < 0) {
                                            i = 0
                                        }
                                        self.pagePicker.selectRow(i ?? 0, inComponent: 0, animated: true)
                                    }
                                } else {
                                    let msg = json["msg"].stringValue
                                    DispatchQueue.main.async
                                        {
                                            self.displayMessage(userMessage: msg)
                                    }
                                    return
                                }
                                
                            } catch {
                                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                                print("error=\(String(describing: error))")
                            }
                        }
                        task.resume()
                        
                        
                    } else {
                        let msg = json["msg"].stringValue
                        DispatchQueue.main.async
                            {
                                self.displayMessage(userMessage: msg)
                        }
                        return
                    }
                    
                } catch {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    print("error=\(String(describing: error))")
                }
            }
            task.resume()
        } else {
            self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
        }
    }
    
    func getSoundList() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/sound/list")
            
            var request = URLRequest(url: url!)
            
            request.httpMethod = "GET"
            request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil
                {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    print("error=\(String(describing: error))")
                    return
                }
                guard let data = data else {
                    self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                    return
                }
                do
                {
                    let json = try JSON(data: data)
                    
                    if json["success"].bool ?? false {
                        let arrayNames = json["result"].arrayValue.map({$0["name"].stringValue})
                        let arrayIds = json["result"].arrayValue.map({$0["id"].stringValue})
                        self.soundPickerData += arrayNames
                        self.soundPickerId += arrayIds
                        DispatchQueue.main.async {
                            self.soundPicker.reloadAllComponents()
                        }
                    } else {
                        let msg = json["msg"].stringValue
                        DispatchQueue.main.async
                            {
                                self.displayMessage(userMessage: msg)
                        }
                        return
                    }
                    
                } catch {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    print("error=\(String(describing: error))")
                }
            }
            task.resume()
        } else {
            self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == pagePicker {
            return pagePickerData.count
        } else if pickerView == soundPicker {
            return soundPickerData.count
        }
        return pagePickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == pagePicker {
            if row > pagePickerData.count - 1 {
                return pagePickerData[pagePickerData.count - 1]
            } else {
                return pagePickerData[row]
            }
        } else if pickerView == soundPicker {
            if row > soundPickerData.count - 1 {
                return soundPickerData[soundPickerData.count - 1]
            } else {
                return soundPickerData[row]
            }
        }
        if row > pagePickerData.count - 1 {
            return pagePickerData[pagePickerData.count - 1]
        } else {
            return pagePickerData[row]
        }
    }
}

