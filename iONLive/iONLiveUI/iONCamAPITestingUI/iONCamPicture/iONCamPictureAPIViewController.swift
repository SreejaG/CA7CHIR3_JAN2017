
import UIKit

class iONCamPictureAPIViewController: UIViewController {
    
    static let identifier = "iONCamPictureAPIViewController"
    
    var loadingOverlay: UIView?
    
    @IBOutlet var burstIntervalPickerView: UIPickerView!
    @IBOutlet var qualityPickerView: UIPickerView!
    @IBOutlet var scalePickerView: UIPickerView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet var burstCountTextField: UITextField!
    @IBOutlet var inputBurstIdPickerView: UIPickerView!
    
    let requestManager = RequestManager.sharedInstance
    let iOnLiveCameraPictureCaptureManager = iOnLiveCameraPictureCapture.sharedInstance
    var burstIdDataSource : [String] = []
    var selectedBurstId = ""
    
    //PRAGMA MARK :- dataSource
    let burstIntervalData = ["333ms","100ms","200ms","5000ms","10000ms","30000ms","60000ms"]
    let scalePickerData = ["1", "2", "4", "8"]
    
    //PRAGMA MARK :- selected values
    var selectedScale = ""
    var selectedQuality = ""
    var selectedBurstInterval = ""
    var selectedBurstCount = ""
    
    //PRAGMA MARK: Load view
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    //PRAGMA MARK:- Initializers
    func initialise()
    {
        burstCountTextField.delegate = self
        self.imageLoadingIndicator.isHidden = true
        updatePickerDataSource()
    }
    
    //PRAGMA MARK: helper methods
    func updatePickerDataSource()
    {
        let status = IONLiveCameraStatusUtility()
        status.getiONLiveCameraStatus(success: { (response) -> () in
            self.burstIdDataSource = status.getCatalogStatus()!
            self.inputBurstIdPickerView.reloadAllComponents()
            if (self.burstIdDataSource.count > 0 )
            {
                self.selectedBurstId = self.burstIdDataSource[0]
            }
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "error", message: "error")
        }
    }
    
    //PRAGMA MARK:- Button Actions
    @IBAction func didTapDeleteAll(_ sender: Any)
    {
        self.deleteAllPictures()
    }
    
    @IBAction func didTapGetPicture(_ sender: Any)
    {
        selectedBurstCount = burstCountTextField.text!
        self.captureiONLiveCamImage()
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapCancelSnaps(_ sender: Any) {
        self.cancelSnaps()
    }
    
    @IBAction func didTapDeletePictureWithBurstId(_ sender: Any) {
        if self.selectedBurstId.isEmpty
        {
            ErrorManager.sharedInstance.alert(title: "Invalid Burst Id", message: "Please enter valid Burst Id.")
        }
        else
        {
            self.deleteiONLiveCamImage(burstId: self.selectedBurstId)
        }
    }
    
    //PRAGMA MARK:- API call
    func captureiONLiveCamImage()
    {
        showOverlay()
        validateBurstCount()
        
        iOnLiveCameraPictureCaptureManager.getiONLiveCameraPictureId(scale: selectedScale, burstCount: selectedBurstCount, burstInterval: selectedBurstInterval, quality: selectedQuality, success: { (response) -> () in
            self.updatePickerDataSource()
            ErrorManager.sharedInstance.alert(title: "Success BurstId found", message:"\(response as? [String: AnyObject])")
            self.iONLiveCamGetPictureSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.iONLiveCamGetPictureFailureHandler(error: error, code: message)
            return
        }
    }
    
    //For testing iOnLiveCamPictureDelete API
    func deleteiONLiveCamImage(burstId: String!)
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.deleteiONLiveCameraPicture(burstID: burstId, success: { (response) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamDeletePictureSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamDeletePictureFailureHandler(error: error, code: message)
            return
        }
    }
    
    func deleteAllPictures()
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.deleteAllIONLiveCameraPicture(success: { (response) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamDeletePictureSuccessHandler(response: response)
        }) { (error, code) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamDeletePictureFailureHandler(error: error, code: code)
            return
        }
    }
    
    func cancelSnaps()
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.cancelSnaps(success: { (response) -> () in
            self.removeOverlay()
            self.iONLiveCamCancelSnaps(response: response)
        }) { (error, code) -> () in
            self.removeOverlay()
            ErrorManager.sharedInstance.alert(title: "Error", message: error?.localizedDescription)
        }
    }
    
    //PRAGMA MARK:- API response Handlers
    func iONLiveCamGetPictureSuccessHandler(response:AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            if let burstId = json["burstID"]
            {
                let id:String = burstId as! String
                // push result VC and load image
                let apiStoryBoard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
                let resultVC = apiStoryBoard.instantiateViewController(withIdentifier: iONCamPictureAPIResultViewController.identifier) as! iONCamPictureAPIResultViewController
                resultVC.imageBurstId = id
                self.navigationController?.pushViewController(resultVC, animated: true)
            }
        }
        else
        {
            ErrorManager.sharedInstance.alert(title: "responce error", message: "Responce Error occured")
        }
    }
    
    func iONLiveCamGetPictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
        }
        else{
            ErrorManager.sharedInstance.alert(title: "responce error", message: "Responce Error occured")
        }
    }
    
    func iONLiveCamDeletePictureSuccessHandler(response:AnyObject?)
    {
        self.removeOverlay()
        if (response as? [String: AnyObject]) != nil
        {
            ErrorManager.sharedInstance.alert(title: "Success", message: "Successfully deleted picture")
        }
        else
        {
            ErrorManager.sharedInstance.alert(title: "responce error", message: "Responce Error occured")
        }
    }
    
    func iONLiveCamCancelSnaps(response:AnyObject?)
    {
        self.removeOverlay()
        if (response as? [String: AnyObject]) != nil
        {
            ErrorManager.sharedInstance.alert(title: "Success", message: "Cancel all ongoing image capture bursts")
        }
        else
        {
            ErrorManager.sharedInstance.alert(title: "responce error", message: "Responce Error occured")
        }
    }
    
    func iONLiveCamDeletePictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        ErrorManager.sharedInstance.alert(title: "Error", message: error?.localizedDescription)
    }
    
    //PRAGMA MARK:- Loading indicator Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView = IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRect(x:0, y:64, width:self.view.frame.width, height:self.view.frame.height)
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
        else if pickerView.isEqual(inputBurstIdPickerView)
        {
            return (burstIdDataSource.count)
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
        else if pickerView.isEqual(inputBurstIdPickerView)
        {
            return burstIdDataSource[row]
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
    
    //PRAGMA MARK:- validate Burst Count
    func validateBurstCount()
    {
        if selectedBurstCount.isEmpty == false
        {
            if !isValidBurstCount(burstCount: selectedBurstCount)
            {
                ErrorManager.sharedInstance.alert(title: "Invalid Burst Count", message: "Please enter valid Burst Count.")
            }
        }
    }
    
    func validateBurstCountTextField(textField:UITextField)
    {
        if let burstCount = textField.text
        {
            if isValidBurstCount(burstCount: burstCount) || (burstCount.isEmpty)
            {
                selectedBurstCount = burstCount
            }
            else{
                ErrorManager.sharedInstance.alert(title: "Invalid Burst Count", message: "Please enter valid Burst Count.")
            }
        }
    }
    
    func isValidBurstCount(burstCount:String) -> Bool
    {
        switch selectedBurstInterval
        {
        case "333ms":
            if burstCount == "3"
            {
                return true;
            }
            break
        case "100ms":
            if burstCount == "10"
            {
                return true;
            }
            break
        case "200ms":
            if (burstCount == "5") || (burstCount == "10")
            {
                return true;
            }
            break
        case "":
            return isValidBurstCountRange(burstCount: burstCount)
        default:
            return isValidBurstCount(burstCount: burstCount)
        }
        return false
    }
    
    func isValidBurstCountRange(burstCount:String) -> Bool{
        let intVal = Int(burstCount)
        if (intVal! >= 1) && (intVal! <= 16777215)
        {
            return true
        }
        return false
    }
}

//PRAGMA MARK:- Pickerview delegate datasource
extension iONCamPictureAPIViewController:UIPickerViewDelegate, UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return getNumberOfElementsInPickerView(pickerView: pickerView)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return getPickerViewData(pickerView: pickerView, ForRow: row)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateSelectedValueFromPickerView(pickerView: pickerView, selectedRow: row)
    }
}

//PRAGMA MARK:- TextField Delegate
extension iONCamPictureAPIViewController:UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        validateTextField(textField: textField)
        return false
    }
    
    func validateTextField(textField: UITextField)
    {
        if textField.isEqual(burstCountTextField)
        {
            validateBurstCountTextField(textField: textField)
        }
    }
}

