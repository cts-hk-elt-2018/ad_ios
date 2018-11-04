//
//  LuckyDrawViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import KeychainSwift
import SwiftyJSON

class LuckyDrawViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var giftPicker: UIPickerView!
    @IBOutlet weak var numberPicker: UIPickerView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var redrawButton: UIButton!
    @IBOutlet weak var nextSessionButton: UIButton!
    
    
    var giftPickerData: [String] = [String]()
    var giftPickerId: [String] = [String]()
    var numberPickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.giftPicker.delegate = self
        self.giftPicker.dataSource = self
        self.numberPicker.delegate = self
        self.numberPicker.dataSource = self
        
        giftPickerData = ["--- Gift ---"]
        giftPickerId = ["0"]
        numberPickerData = ["--- No. of Prize Winner(s) ---", "1 - One", "2 - Two", "3 - Three", "4 - Four", "5 - Five", "6 - Six", "7 - Seven", "8 - Eight", "9 - Nine", "10 - Ten"]
        getGiftList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.giftPicker.reloadAllComponents()
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
    
    func getGiftList() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/luckydraw/list")
            
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
                        self.giftPickerData += arrayNames
                        self.giftPickerId += arrayIds
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
                    print("error2")
                    print("error=\(String(describing: error))")
                }
            }
            task.resume()
        } else {
            self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
        }
    }
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == giftPicker {
            return 1
        } else if pickerView == numberPicker {
            return 1
        }
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == giftPicker {
            return giftPickerData.count
        } else if pickerView == numberPicker {
            return numberPickerData.count
        }
        return numberPickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == giftPicker {
            return giftPickerData[row]
        } else if pickerView == numberPicker {
            return numberPickerData[row]
        }
        return numberPickerData[row]
    }
    
    @IBAction func showButtonTapped(_ sender: Any) {
        let currentRow = self.giftPicker.selectedRow(inComponent: 0)
        if currentRow > 0 {
            let giftId = giftPickerId[currentRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/luckydraw/\(giftId)")
                
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
                        print(json["success"].bool!)
                        
                        if json["success"].bool! {
                            DispatchQueue.main.async
                            {
                                self.giftPicker.isUserInteractionEnabled = false
                                self.giftPicker.alpha = 0.6
                                self.showButton.isEnabled = false
                                self.numberPicker.isUserInteractionEnabled = true
                                self.numberPicker.alpha = 1
                                self.drawButton.isEnabled = true
                                self.resetButton.isEnabled = true
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
                        print("error2")
                        print("error=\(String(describing: error))")
                    }
                }
                task.resume()
            } else {
                self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
            }
        }
    }
    
    @IBAction func drawButtonTapped(_ sender: Any) {
        let currentRow = self.giftPicker.selectedRow(inComponent: 0)
        let currentNumber = self.numberPicker.selectedRow(inComponent: 0)
        if currentRow > 0 && currentNumber > 0 {
            let giftId = giftPickerId[currentRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/luckydraw/\(giftId)")
                
                var request = URLRequest(url: url!)
                
                request.httpMethod = "POST"
                request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "content-type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let postString = ["winnerCount": currentNumber] as [String: Int]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
                } catch let error {
                    print(error.localizedDescription)
                    self.displayMessage(userMessage: "Something went wrong...")
                }
                
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
                        print(json["success"].bool!)
                        
                        if json["success"].bool! {
                            DispatchQueue.main.async
                                {
                                    //TODO: Handle Winners
                                    //json["winner"]
                                    self.numberPicker.isUserInteractionEnabled = false
                                    self.numberPicker.alpha = 0.6
                                    self.drawButton.isEnabled = false
                                    self.resetButton.isEnabled = false
                                    self.redrawButton.isEnabled = true
                                    self.nextSessionButton.isEnabled = true
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
                        print("error2")
                        print("error=\(String(describing: error))")
                    }
                }
                task.resume()
            } else {
                self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
            }
        }
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        DispatchQueue.main.async
        {
            self.giftPicker.selectRow(0, inComponent: 0, animated: true)
            self.giftPicker.isUserInteractionEnabled = true
            self.giftPicker.alpha = 1
            self.numberPicker.isUserInteractionEnabled = false
            self.numberPicker.alpha = 0.6
            self.numberPicker.selectRow(0, inComponent: 0, animated: true)
            self.showButton.isEnabled = true
            self.drawButton.isEnabled = false
            self.resetButton.isEnabled = false
        }
    }
    
    @IBAction func redrawButtonTapped(_ sender: Any) {
    }
    
    @IBAction func nextSessionButtonTapped(_ sender: Any) {
        DispatchQueue.main.async
            {
                // TODO: empty winners data in table
                self.giftPicker.selectRow(0, inComponent: 0, animated: true)
                self.giftPicker.isUserInteractionEnabled = true
                self.giftPicker.alpha = 1
                self.numberPicker.selectRow(0, inComponent: 0, animated: true)
                self.showButton.isEnabled = true
                self.redrawButton.isEnabled = false
                self.nextSessionButton.isEnabled = false
        }
    }
}

