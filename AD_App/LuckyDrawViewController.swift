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

class LuckyDrawViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var giftPicker: UIPickerView!
    @IBOutlet weak var numberPicker: UIPickerView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var redrawButton: UIButton!
    @IBOutlet weak var nextSessionButton: UIButton!
    @IBOutlet weak var winnerTableView: UITableView!
    
    
    var giftPickerData: [String] = [String]()
    var giftPickerId: [String] = [String]()
    var giftPickerWinnerNum: [Int] = [Int]()
    var numberPickerData: [String] = [String]()
    var winnerTableData: [String] = [String]()
    var winnerTableId: [String] = [String]()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.giftPicker.delegate = self
        self.giftPicker.dataSource = self
        self.numberPicker.delegate = self
        self.numberPicker.dataSource = self
        self.winnerTableView.delegate = self
        self.winnerTableView.dataSource = self
        
        self.winnerTableView.allowsMultipleSelection = true
        
        numberPickerData = ["--- No. of Prize Winner(s) ---", "1 - One", "2 - Two", "3 - Three", "4 - Four", "5 - Five", "6 - Six", "7 - Seven", "8 - Eight", "9 - Nine", "10 - Ten"]
        getGiftList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.giftPicker.reloadAllComponents()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return winnerTableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        let rowIsSelected = selectedIndexPaths != nil && selectedIndexPaths!.contains(indexPath)
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        
        cell!.accessoryType = rowIsSelected ? .checkmark : .none
        cell!.textLabel?.text = self.winnerTableData[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath as IndexPath)?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath as IndexPath)?.accessoryType = .none
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow,
            indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.cellForRow(at: indexPath as IndexPath)?.accessoryType = .none
            return nil
        }
        return indexPath
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
                        self.giftPickerData = ["--- Gift ---"]
                        self.giftPickerId = ["0"]
                        self.giftPickerWinnerNum = [0]
                        let arrayNames = json["result"].arrayValue.map({$0["drawed"].boolValue ? "(Drawed) " + $0["displayName"].stringValue : $0["displayName"].stringValue})
                        let arrayIds = json["result"].arrayValue.map({$0["id"].stringValue})
                        let arrayWinnerNum = json["result"].arrayValue.map({$0["winnerLen"].intValue})
                        self.giftPickerData += arrayNames
                        self.giftPickerId += arrayIds
                        self.giftPickerWinnerNum += arrayWinnerNum
                        DispatchQueue.main.async {
                            self.giftPicker.reloadAllComponents()
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
                        
                        if json["success"].bool! {
                            DispatchQueue.main.async
                            {
                                self.giftPicker.isUserInteractionEnabled = false
                                self.giftPicker.alpha = 0.6
                                self.showButton.isEnabled = false
                                self.numberPicker.selectRow(self.giftPickerWinnerNum[currentRow], inComponent: 0, animated: true)
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
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: nil, message: "Are you going to draw?", preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(cancelAction)
                
                let drawAction = UIAlertAction(title: "Draw", style: .default) { (action) in
                    // when destroy is tapped
                    self.dismiss(animated: true, completion: nil)
                
                    let giftId = self.giftPickerId[currentRow]
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
                                
                                if json["success"].bool! {
                                    DispatchQueue.main.async
                                        {
                                            self.winnerTableData = json["winners"].arrayValue.map({$0["username"].stringValue + " " + $0["firstName"].stringValue + " " + $0["lastName"].stringValue})
                                            self.winnerTableId = json["winners"].arrayValue.map({$0["id"].stringValue})
                                            self.winnerTableView.reloadData()
                                            self.winnerTableView.isUserInteractionEnabled = true
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
                                print("error=\(String(describing: error))")
                            }
                        }
                        task.resume()
                    } else {
                        self.displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
                    }
                
                }
                alertController.addAction(drawAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        DispatchQueue.main.async
        {
            self.getGiftList()
//            self.giftPicker.selectRow(0, inComponent: 0, animated: true)
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
        let selectedRows = self.winnerTableView.indexPathsForSelectedRows
        let selectedRowsIndex = selectedRows?.map { $0.row }
        let selectedUserIds = selectedRows?.map { self.winnerTableId[$0.row] }
        var selectedUserIdsInt: [Int] = [Int]()
        var intInArray : Int
        var i : Int = 0
        for item in selectedUserIds! {
            intInArray = Int(item)!
            selectedUserIdsInt.insert(intInArray, at:i )
            i += 1
        }
        
        let currentGiftRow = self.giftPicker.selectedRow(inComponent: 0)
        
        if selectedRows?.count ?? 0 > 0 {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: nil, message: "Selected winners will be removed and same numbers of winners will be re-draw out.", preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(cancelAction)

                let redrawAction = UIAlertAction(title: "Remove and Redraw", style: .destructive) { (action) in
                    // when redraw is tapped
                    self.dismiss(animated: true, completion: nil)



                    //START
                    let giftId = self.giftPickerId[currentGiftRow]
                    if reachability.connection != .none {
                        let keychain = KeychainSwift()
                        let accessToken = keychain.get("accessToken")


                        let url = URL(string: "\(v_host)/api/luckydraw/\(giftId)")

                        var request = URLRequest(url: url!)

                        request.httpMethod = "PUT"
                        request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                        request.addValue("application/json", forHTTPHeaderField: "content-type")
                        request.addValue("application/json", forHTTPHeaderField: "Accept")

                        let postString = ["removedWinnersId": selectedUserIdsInt] as [String: Array<Int>]

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

                                if json["success"].bool! {
                                    DispatchQueue.main.async
                                        {
                                            self.winnerTableData = self.winnerTableData.enumerated().filter { !selectedRowsIndex!.contains($0.offset) }.map { $0.element }
                                            self.winnerTableId = self.winnerTableId.enumerated().filter { !selectedRowsIndex!.contains($0.offset) }.map { $0.element }
                                            self.winnerTableData += json["winners"].arrayValue.map({$0["username"].stringValue + " " + $0["firstName"].stringValue + " " + $0["lastName"].stringValue})
                                            self.winnerTableId += json["winners"].arrayValue.map({$0["id"].stringValue})
                                            self.winnerTableView.reloadData()
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
                    //END
                }
                alertController.addAction(redrawAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    
    @IBAction func nextSessionButtonTapped(_ sender: Any) {
        DispatchQueue.main.async
            {
                self.winnerTableData = []
                self.winnerTableId = []
                self.winnerTableView.reloadData()
                self.winnerTableView.isUserInteractionEnabled = false
                self.getGiftList()
                let currentRow = self.giftPicker.selectedRow(inComponent: 0)
                self.giftPicker.selectRow(currentRow + 1, inComponent: 0, animated: true)
                self.giftPicker.isUserInteractionEnabled = true
                self.giftPicker.alpha = 1
                self.numberPicker.selectRow(0, inComponent: 0, animated: true)
                self.showButton.isEnabled = true
                self.redrawButton.isEnabled = false
                self.nextSessionButton.isEnabled = false
        }
    }
}

