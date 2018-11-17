//
//  AwardViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 11/11/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import KeychainSwift
import SwiftyJSON

class HeadlineTableViewCell: UITableViewCell {
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
}

class AwardViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var awardPicker: UIPickerView!
    @IBOutlet weak var awardeePicker: UIPickerView!
    @IBOutlet weak var showAwardButton: UIButton!
    @IBOutlet weak var showAwardeeButton: UIButton!
    @IBOutlet weak var nextAwardButton: UIButton!
    @IBOutlet weak var awardeeTable: UITableView!
    
    var awardPickerData: [String] = [String]()
    var awardPickerId: [String] = [String]()
    var awardeePickerData: [String] = [String]()
    var awardeePickerId: [String] = [String]()
    var checkedInAwardeeTableData: [String] = [String]()
    var checkedInAwardeeTableDetail: [String] = [String]()
    var notCheckedInAwardeeTableData: [String] = [String]()
    var notCheckedInAwardeeTableDetail: [String] = [String]()
    var awardeeTableSection: [String] = [String]()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.awardPicker.delegate = self
        self.awardPicker.dataSource = self
        self.awardeePicker.delegate = self
        self.awardeePicker.dataSource = self
        self.awardeeTable.delegate = self
        self.awardeeTable.dataSource = self
        
        awardPickerData = ["--- Award ---"]
        awardPickerId = ["0"]
        
        awardeePickerData = ["--- Awardee ---"]
        awardeePickerId = ["0"]
        
        awardeeTableSection = ["Checked in", "Not checked in"]
        
        getAwardList()
        getAwardeeStatus()
    }
    
    @IBAction func showAwardButtonTapped(_ sender: Any) {
        let currentRow = self.awardPicker.selectedRow(inComponent: 0)
        if currentRow > 0 {
            let awardId = self.awardPickerId[currentRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/award/\(awardId)")
                
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
                            let arrayNames = json["result"].arrayValue.map({$0["User"]["firstName"].stringValue + " " + $0["User"]["lastName"].stringValue + " (" + $0["User"]["username"].stringValue + ")"})
                            let arrayIds = json["result"].arrayValue.map({$0["id"].stringValue})
                            self.awardeePickerData += arrayNames
                            self.awardeePickerId += arrayIds
                            DispatchQueue.main.async {
                                self.awardPicker.alpha = 0.6
                                self.awardPicker.isUserInteractionEnabled = false
                                self.awardeePicker.reloadAllComponents()
                                self.awardeePicker.alpha = 1
                                self.awardeePicker.isUserInteractionEnabled = true
                                self.showAwardeeButton.isEnabled = true
                                self.nextAwardButton.isEnabled = true
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
    
    
    @IBAction func showAwardeeButtonTapped(_ sender: Any) {
        let currentAwardRow = self.awardPicker.selectedRow(inComponent: 0)
        let currentAwardeeRow = self.awardeePicker.selectedRow(inComponent: 0)
        if currentAwardRow > 0 && currentAwardeeRow > 0 {
            let awardId = self.awardPickerId[currentAwardRow]
            let awardeeId = self.awardeePickerId[currentAwardeeRow]
            if reachability.connection != .none {
                let keychain = KeychainSwift()
                let accessToken = keychain.get("accessToken")
                
                
                let url = URL(string: "\(v_host)/api/award/\(awardId)/\(awardeeId)")
                
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
    
    @IBAction func nextAwardButtonTapped(_ sender: Any) {
        DispatchQueue.main.async
            {
                self.awardPicker.selectRow(0, inComponent: 0, animated: true)
                self.awardPicker.isUserInteractionEnabled = true
                self.awardPicker.alpha = 1
                self.awardeePicker.selectRow(0, inComponent: 0, animated: true)
                self.awardeePicker.isUserInteractionEnabled = false
                self.awardeePicker.alpha = 0.6
                self.awardeePickerData = ["--- Awardee ---"]
                self.awardeePickerId = ["0"]
                self.awardeePicker.reloadAllComponents()
                self.showAwardButton.isEnabled = true
                self.showAwardeeButton.isEnabled = false
                self.nextAwardButton.isEnabled = false
        }
    }
    
    @IBAction func updateStatusButtonTapped(_ sender: Any) {
        getAwardeeStatus()
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
    
    func getAwardList() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/award/list")
            
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
                        self.awardPickerData += arrayNames
                        self.awardPickerId += arrayIds
                        DispatchQueue.main.async {
                            self.awardPicker.reloadAllComponents()
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
    
    func getAwardeeStatus() {
        if reachability.connection != .none {
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let url = URL(string: "\(v_host)/api/award/awardeeList")
            
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
                        self.checkedInAwardeeTableData = []
                        self.checkedInAwardeeTableDetail = []
                        self.notCheckedInAwardeeTableData = []
                        self.notCheckedInAwardeeTableDetail = []
                        for awardee in json["result"].arrayValue {
                            if awardee["User"]["isCheckedIn"].bool ?? false {
                                self.checkedInAwardeeTableData.append(awardee["User"]["firstName"].stringValue + " " + awardee["User"]["lastName"].stringValue + " (" + awardee["User"]["username"].stringValue + ")")
                                self.checkedInAwardeeTableDetail.append(awardee["Award"]["name"].stringValue)
                            } else {
                                self.notCheckedInAwardeeTableData.append(awardee["User"]["firstName"].stringValue + " " + awardee["User"]["lastName"].stringValue + " (" + awardee["User"]["username"].stringValue + ")")
                                self.notCheckedInAwardeeTableDetail.append(awardee["Award"]["name"].stringValue)
                            }
                        }
                        DispatchQueue.main.async {
                            self.awardeeTable.reloadData()
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
        if pickerView == awardPicker {
            return awardPickerData.count
        } else if pickerView == awardeePicker {
            return awardeePickerData.count
        }
        return awardeePickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == awardPicker {
            return awardPickerData[row]
        } else if pickerView == awardeePicker {
            return awardeePickerData[row]
        }
        return awardeePickerData[row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return awardeeTableSection.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return awardeeTableSection[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return checkedInAwardeeTableData.count
        } else if section == 1 {
            return notCheckedInAwardeeTableData.count
        }
        return notCheckedInAwardeeTableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath) as! HeadlineTableViewCell
        cell.isUserInteractionEnabled = false
        if indexPath.section == 0 {
            cell.headlineLabel?.text = checkedInAwardeeTableData[indexPath.row]
            cell.detailLabel?.text = checkedInAwardeeTableDetail[indexPath.row]
            return cell
        } else if indexPath.section == 1 {
            cell.headlineLabel?.text = notCheckedInAwardeeTableData[indexPath.row]
            cell.detailLabel?.text = notCheckedInAwardeeTableDetail[indexPath.row]
            return cell
        }
        return cell
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
