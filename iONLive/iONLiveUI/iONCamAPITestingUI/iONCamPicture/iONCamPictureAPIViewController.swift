//
//  iONCamPictureAPIViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit



class iONCamPictureAPIViewController: UIViewController {

    static let identifier = "iONCamPictureAPIViewController"
    
    var loadingOverlay: UIView?
    
    @IBOutlet var burstIntervalPickerView: UIPickerView!
    @IBOutlet var qualityPickerView: UIPickerView!
    @IBOutlet var scalePickerView: UIPickerView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet var burstCountTextField: UITextField!
    
    let requestManager = RequestManager.sharedInstance
    let iOnLiveCameraPictureCaptureManager = iOnLiveCameraPictureCapture.sharedInstance

    //PRAGMA MARK :- dataSource
//    let scalePickerData = ["1=4000x3000 (12Mpixel)", "2=3840X2160(8Mpixel)", "4=2560X1920(5Mpixel)", "8=1920x1080(2Mpixel)"]
    let burstIntervalData = ["333ms","100ms","200ms","5000ms","10000ms","30000ms","60000ms"]
    let scalePickerData = ["1", "2", "4", "8"]
    
    //PRAGMA MARK :- selected values
    var selectedScale = "1"
    var selectedQuality = "1"
    var selectedBurstInterval = "333ms"
    var selectedBurstCount = ""
    
    //PRAGMA MARK: Load view
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //PRAGAMA MARK :- Initializers
    func initialise()
    {
        burstCountTextField.delegate = self
//        burstCountTextField.keyboardType = UIKeyboardType.NumberPad
        self.imageLoadingIndicator.hidden = true
    }
    
    @IBAction func deleteButtonClicked(sender: AnyObject)
    {
        self.deleteiONLiveCamImage(true, burstId: nil)
    }
    
    @IBAction func getButtonClicked(sender: AnyObject)
    {
        selectedBurstCount = burstCountTextField.text!
        self.captureiONLiveCamImage()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //PRAGMA MARK:- API call
    /////////For testing iOnLiveCamPictureCapture API
    func captureiONLiveCamImage()
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.getiONLiveCameraPictureId(selectedScale, burstCount: selectedBurstCount, burstInterval: selectedBurstInterval, quality: selectedQuality, success: { (response) -> () in
            ErrorManager.sharedInstance.alert("Success BurstId found", message:"\(response as? [String: AnyObject])")
            self.iONLiveCamGetPictureSuccessHandler(response)
            
            }) { (error, message) -> () in
                self.iONLiveCamGetPictureFailureHandler(error, code: message)
                return
        }
    }
    
    
    func iONLiveCamGetPictureSuccessHandler(response:AnyObject?)
    {
        print("entered download pic")
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            if let burstId = json["burstID"]
            {
                let id:String = burstId as! String
                // push result VC and load image
                let apiStoryBoard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
                let resultVC = apiStoryBoard.instantiateViewControllerWithIdentifier(iONCamPictureAPIResultViewController.identifier) as! iONCamPictureAPIResultViewController
                resultVC.imageBurstId = id
                self.navigationController?.pushViewController(resultVC, animated: true)
                
            }
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func iONLiveCamGetPictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    ////////////////////////////////////////////////
    
    /////////For testing iOnLiveCamPictureDelete API
    func deleteiONLiveCamImage(cancelBurst: Bool, burstId: String?)
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.deleteiONLiveCameraPicture(cancelBurst, burstID: burstId, success: { (response) -> () in
            self.iONLiveCamDeletePictureSuccessHandler(response)
            }) { (error, message) -> () in
                self.iONLiveCamDeletePictureFailureHandler(error, code: message)
                return
        }
    }
    
    
    func iONLiveCamDeletePictureSuccessHandler(response:AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print("success = \(json["burstID"]))")
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func iONLiveCamDeletePictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    ////////////////////////////////////////////////
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
}

//PRAGMA MARK:- Helper Methods
extension iONCamPictureAPIViewController
{
    func getNumberOfElementsInPickerView(pickerView: UIPickerView) ->Int
    {
        if pickerView.isEqual(burstIntervalPickerView)
        {
            return burstIntervalData.count
        }
        else if pickerView.isEqual(scalePickerView)
        {
            return scalePickerData.count
        }
        else if pickerView.isEqual(qualityPickerView)
        {
            return 100
        }
        return 0
    }
    
    func getPickerViewData(pickerView:UIPickerView , ForRow row:Int) -> String
    {
        if pickerView.isEqual(burstIntervalPickerView)
        {
            return burstIntervalData[row]
        }
        else if pickerView.isEqual(scalePickerView)
        {
            return scalePickerData[row]
        }
        else if pickerView.isEqual(qualityPickerView)
        {
            if row < 100
            {
                return String(row + 1)
            }
        }
        return ""
    }
    
    func updateSelectedValueFromPickerView(pickerView: UIPickerView, selectedRow row: Int)
    {
        if pickerView.isEqual(burstIntervalPickerView)
        {
            selectedBurstInterval = burstIntervalData[row]
        }
        else if pickerView.isEqual(scalePickerView)
        {
            selectedScale = scalePickerData[row]
        }
        else if pickerView.isEqual(qualityPickerView)
        {
            if row < 100
            {
                selectedQuality = String(row+1)
            }
        }
    }
}

//PRAGMA MARK:- Pickerview delegate datasource

extension iONCamPictureAPIViewController:UIPickerViewDelegate , UIPickerViewDataSource
{
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return getNumberOfElementsInPickerView(pickerView)
        
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return getPickerViewData(pickerView, ForRow: row)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
            updateSelectedValueFromPickerView(pickerView, selectedRow: row)
    }
}

extension iONCamPictureAPIViewController:UITextFieldDelegate
{
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return false
    }
}

