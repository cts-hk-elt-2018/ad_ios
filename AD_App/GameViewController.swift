//
//  GameViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 11/11/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import KeychainSwift
import SwiftyJSON

class GameViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var gameQuestionPickerView: UIPickerView!
    @IBOutlet weak var nextSessionButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var nextResponseButton: UIButton!
    @IBOutlet weak var previousResponseButton: UIButton!
    
    var gameQuestionPickerData: [String] = [String]()
    var gameQuestionPickerId: [String] = [String]()
    var questionId: String = ""
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.gameQuestionPickerView.delegate = self
        self.gameQuestionPickerView.dataSource = self
        
        getGameQuestionList()
    }
    @IBAction func showButtonTapped(_ sender: Any) {
        let currentRow = self.gameQuestionPickerView.selectedRow(inComponent: 0)
        if currentRow > 0 {
            questionId = gameQuestionPickerId[currentRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/game/\(questionId)")
                
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
                        
                        if json["success"].bool! {
                            DispatchQueue.main.async
                                {
                                    self.gameQuestionPickerView.isUserInteractionEnabled = false
                                    self.gameQuestionPickerView.alpha = 0.6
                                    self.showButton.isEnabled = false
                                    self.nextSessionButton.isEnabled = true
                                    self.nextResponseButton.isEnabled = true
                                    self.previousResponseButton.isEnabled = true
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
    }
    
    @IBAction func nextSessionButtonTapped(_ sender: Any) {
        getGameQuestionList()
        let currentRow = self.gameQuestionPickerView.selectedRow(inComponent: 0)
        self.gameQuestionPickerView.selectRow(currentRow + 1, inComponent: 0, animated: true)
        self.gameQuestionPickerView.isUserInteractionEnabled = true
        self.gameQuestionPickerView.alpha = 1
        self.showButton.isEnabled = true
        self.nextSessionButton.isEnabled = false
        self.nextResponseButton.isEnabled = false
        self.previousResponseButton.isEnabled = false
    }
    @IBAction func nextResponseButtonTapped(_ sender: Any) {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/game/\(questionId)/next")
            
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
    @IBAction func previousResponseButtonTapped(_ sender: Any) {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/game/\(questionId)/previous")
            
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
    
    func getGameQuestionList() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/game/list")
            
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
                        
                        self.gameQuestionPickerData = ["--- Question ---"]
                        self.gameQuestionPickerId = ["0"]
                        let arrayNames = json["result"].arrayValue.map({$0["played"].boolValue ? "(Played) " + $0["displayQuestion"].stringValue : $0["displayQuestion"].stringValue})
                        let arrayIds = json["result"].arrayValue.map({$0["id"].stringValue})
                        self.gameQuestionPickerData += arrayNames
                        self.gameQuestionPickerId += arrayIds
                        DispatchQueue.main.async {
                            self.gameQuestionPickerView.reloadAllComponents()
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
        return gameQuestionPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return gameQuestionPickerData[row]
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
