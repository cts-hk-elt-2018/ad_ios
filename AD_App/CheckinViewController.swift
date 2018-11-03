//
//  CheckinViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 18/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import AVFoundation
import KeychainSwift

class CheckinViewController: UIViewController, UITextFieldDelegate, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var staffIDTextField: UITextField!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var staffIDLabel: UILabel!
    @IBOutlet weak var staffNameLabel: UILabel!
    @IBOutlet weak var checkedInSwitch: UISwitch!
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView:UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.addDoneButtonOnKeyboard()
        staffIDTextField.delegate = self

        // Do any additional setup after loading the view.
        
        if AVCaptureDevice.authorizationStatus(for: .video) !=  .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if !granted {
                    print("Failed to grant the camera device")
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Camera", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                            print("OK button pressed")
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                            }
                        }
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            })
        }
        
        captureSession = AVCaptureSession()
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)

        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)

            // Set the input device on the capture session.
            captureSession.addInput(input)

            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)

            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.qr]


            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = cameraView.layer.bounds
            cameraView.layer.addSublayer(videoPreviewLayer!)

            // Start video capture.
            captureSession.startRunning()

            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()

            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                cameraView.addSubview(qrCodeFrameView)
                cameraView.bringSubviewToFront(qrCodeFrameView)

            }
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    var currentStaffID: String = ""
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            print("No QR code is detected")
//            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil {
                if metadataObj.stringValue != currentStaffID {
                    print(metadataObj.stringValue!)
                    currentStaffID = metadataObj.stringValue!
                    checkin(staffID: currentStaffID)
                }
                
//                messageLabel.text = metadataObj.stringValue
                //TODO: DO STH
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.staffIDTextField.inputAccessoryView = doneToolbar
        
    }

    
    @IBAction func doneButtonAction(_ sender: UIButton) {
        self.staffIDTextField.resignFirstResponder()
        nextButtonTapped(self.staffIDTextField)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        self.staffIDLabel.text = ""
        self.staffNameLabel.text = ""
        self.checkedInSwitch.setOn(false, animated: false)
        self.checkedInSwitch.isEnabled = false
        self.checkedInSwitch.isHidden = true
        self.staffIDTextField.text = ""
    }


    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == staffIDTextField {
            staffIDTextField.resignFirstResponder()
            nextButtonTapped(textField)
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
    
    func checkOut(staffID: String) {
        var httpMethod: String
        httpMethod = "DELETE"
        
        let myActivityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = false
        myActivityIndicator.startAnimating()
        view.addSubview(myActivityIndicator)
        
        
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        
        let checkinUrl = URL(string: "\(v_host)/api/checkin/1/\(staffID)")
        
        var request = URLRequest(url: checkinUrl!)
        
        request.httpMethod = httpMethod
        request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil
            {
                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                self.staffIDLabel.text = ""
                self.staffNameLabel.text = ""
                self.checkedInSwitch.setOn(false, animated: false)
                self.checkedInSwitch.isEnabled = false
                self.checkedInSwitch.isHidden = true
                self.staffIDTextField.text = ""
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
                        DispatchQueue.main.async
                            {
                                let r_staffID: String? = parseJSON["username"] as? String
                                let r_staffName: String? = parseJSON["name"] as? String
                                
                                if r_staffID?.isEmpty != true {
                                    self.staffIDLabel.text = r_staffID!
                                }
                                if r_staffName?.isEmpty != true{
                                    self.staffNameLabel.text = r_staffName!
                                }
                                self.checkedInSwitch.setOn(true, animated: true)
                                self.checkedInSwitch.isEnabled = true
                                self.checkedInSwitch.isHidden = false
                                
                                self.staffIDTextField.text = ""
                                
                                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        }
                    } else {
                        let msg = parseJSON["msg"] as? String
                        DispatchQueue.main.async
                            {
                                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                                self.staffIDLabel.text = ""
                                self.staffNameLabel.text = ""
                                self.checkedInSwitch.setOn(false, animated: false)
                                self.checkedInSwitch.isEnabled = false
                                self.checkedInSwitch.isHidden = true
                                self.staffIDTextField.text = ""
                                self.displayMessage(userMessage: msg!)
                        }
                        return
                    }
                } else {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")
                    self.staffIDLabel.text = ""
                    self.staffNameLabel.text = ""
                    self.checkedInSwitch.setOn(false, animated: false)
                    self.checkedInSwitch.isEnabled = false
                    self.checkedInSwitch.isHidden = true
                    self.staffIDTextField.text = ""
                }
            } catch {
                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                self.staffIDLabel.text = ""
                self.staffNameLabel.text = ""
                self.checkedInSwitch.setOn(false, animated: false)
                self.checkedInSwitch.isEnabled = false
                self.checkedInSwitch.isHidden = true
                self.staffIDTextField.text = ""
            }
        }
        task.resume()
    }
    
    func checkin(staffID: String) {
        var httpMethod: String
        httpMethod = "POST"
        
        
        if reachability.connection != .none {
            let myActivityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            myActivityIndicator.center = view.center
            myActivityIndicator.hidesWhenStopped = false
            myActivityIndicator.startAnimating()
            view.addSubview(myActivityIndicator)
            
            
            let keychain = KeychainSwift()
            let accessToken = keychain.get("accessToken")
            
            
            let checkinUrl = URL(string: "\(v_host)/api/checkin/1/\(staffID)")
            
            var request = URLRequest(url: checkinUrl!)
            
            request.httpMethod = httpMethod
            request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil
                {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    self.staffIDLabel.text = ""
                    self.staffNameLabel.text = ""
                    self.checkedInSwitch.setOn(false, animated: false)
                    self.checkedInSwitch.isEnabled = false
                    self.checkedInSwitch.isHidden = true
                    self.staffIDTextField.text = ""
                    print("error=\(String(describing: error))")
                    return
                }
                guard let data = data else {
                    // no data
                    return
                }
                do
                {
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                    if let parseJSON = json
                    {
                        let status = parseJSON["success"] as? Bool
                        
                        if status!
                        {
                            DispatchQueue.main.async
                                {
                                    let r_staffID: String? = parseJSON["username"] as? String
                                    let r_staffName: String? = parseJSON["name"] as? String
                                    
                                    if r_staffID?.isEmpty != true {
                                        self.staffIDLabel.text = r_staffID!
                                    }
                                    if r_staffName?.isEmpty != true{
                                        self.staffNameLabel.text = r_staffName!
                                    }
                                    self.checkedInSwitch.setOn(true, animated: true)
                                    self.checkedInSwitch.isEnabled = true
                                    self.checkedInSwitch.isHidden = false
                                    
                                    self.staffIDTextField.text = ""
                                    
                                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            }
                        } else {
                            let msg = parseJSON["msg"] as? String
                            DispatchQueue.main.async
                                {
                                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                                    self.staffIDLabel.text = ""
                                    self.staffNameLabel.text = ""
                                    self.checkedInSwitch.setOn(false, animated: false)
                                    self.checkedInSwitch.isEnabled = false
                                    self.checkedInSwitch.isHidden = true
                                    self.staffIDTextField.text = ""
                                    self.displayMessage(userMessage: msg!)
                            }
                            return
                        }
                    } else {
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")
                        self.staffIDLabel.text = ""
                        self.staffNameLabel.text = ""
                        self.checkedInSwitch.setOn(false, animated: false)
                        self.checkedInSwitch.isEnabled = false
                        self.checkedInSwitch.isHidden = true
                        self.staffIDTextField.text = ""
                    }
                } catch {
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                    self.staffIDLabel.text = ""
                    self.staffNameLabel.text = ""
                    self.checkedInSwitch.setOn(false, animated: false)
                    self.checkedInSwitch.isEnabled = false
                    self.checkedInSwitch.isHidden = true
                    self.staffIDTextField.text = ""
                }
            }
            task.resume()
        } else {
            displayMessage(userMessage: "There is something wrong with your internet Connection. Please check and try again")
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        print("nextButtonTapped")
        currentStaffID = staffIDTextField.text!
        
        if (currentStaffID.isEmpty) {
            self.staffIDLabel.text = ""
            self.staffNameLabel.text = ""
            self.checkedInSwitch.setOn(false, animated: false)
            self.checkedInSwitch.isEnabled = false
            self.checkedInSwitch.isHidden = true
            self.staffIDTextField.text = ""
            displayMessage(userMessage: "StaffID is missing.")
            return
        }
        
        checkin(staffID: currentStaffID)
        
       
    }
    @IBAction func checkedInSwtichChanged(_ sender: Any) {
        let staffID = currentStaffID
        var httpMethod: String
        if checkedInSwitch.isOn {
            httpMethod = "POST"
        } else {
            httpMethod = "DELETE"
        }
        if (staffID.isEmpty) {
            displayMessage(userMessage: "StaffID is missing.")
            self.staffIDLabel.text = ""
            self.staffNameLabel.text = ""
            self.checkedInSwitch.setOn(false, animated: false)
            self.checkedInSwitch.isEnabled = false
            self.checkedInSwitch.isHidden = true
            self.staffIDTextField.text = ""
            return
        }
        
        let myActivityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = false
        myActivityIndicator.startAnimating()
        view.addSubview(myActivityIndicator)
        
        
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        
        let checkinUrl = URL(string: "\(v_host)/api/checkin/1/\(staffID)")
        
        var request = URLRequest(url: checkinUrl!)
        
        request.httpMethod = httpMethod
        request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil
            {
                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
                print("error=\(String(describing: error))")
                self.staffIDLabel.text = ""
                self.staffNameLabel.text = ""
                self.checkedInSwitch.setOn(false, animated: false)
                self.checkedInSwitch.isEnabled = false
                self.checkedInSwitch.isHidden = true
                self.staffIDTextField.text = ""
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
                        DispatchQueue.main.async
                            {
                                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        }
                    } else {
                        let msg = parseJSON["msg"] as? String
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        self.staffIDLabel.text = ""
                        self.staffNameLabel.text = ""
                        self.checkedInSwitch.setOn(false, animated: false)
                        self.checkedInSwitch.isEnabled = false
                        self.checkedInSwitch.isHidden = true
                        self.staffIDTextField.text = ""
                        self.displayMessage(userMessage: msg!)
                        return
                    }
                } else {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.staffIDLabel.text = ""
                    self.staffNameLabel.text = ""
                    self.checkedInSwitch.setOn(false, animated: false)
                    self.checkedInSwitch.isEnabled = false
                    self.checkedInSwitch.isHidden = true
                    self.staffIDTextField.text = ""
                    self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later")
                }
            } catch {
                self.staffIDLabel.text = ""
                self.staffNameLabel.text = ""
                self.checkedInSwitch.setOn(false, animated: false)
                self.checkedInSwitch.isEnabled = false
                self.checkedInSwitch.isHidden = true
                self.staffIDTextField.text = ""
                self.displayMessage(userMessage: "Could not successfully perform this request. Please try again later.")
            }
        }
        task.resume()

        
        
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
