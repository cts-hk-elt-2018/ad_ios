//
//  LuckyDrawViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions

class LuckyDrawViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var numberPicker: UIPickerView!
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Do any additional setup after loading the view, typically from a nib.
        
        self.numberPicker.delegate = self
        self.numberPicker.dataSource = self
        
        pickerData = ["--- No. of Prize Winner(s) ---", "1 - One", "2 - Two", "3 - Three", "4 - Four", "5 - Five", "6 - Six", "7 - Seven", "8 - Eight", "9 - Nine", "10 - Ten"]
    }

    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return pickerData[row]
    }
    
}

