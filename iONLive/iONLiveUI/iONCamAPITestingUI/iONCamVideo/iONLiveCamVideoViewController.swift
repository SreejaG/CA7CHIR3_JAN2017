
import UIKit

class iONLiveCamVideoViewController: UIViewController {

    static let identifier = "iONLiveCamVideoViewController"

    var videoAPIResult =  [String : String]()
    let iONLiveCameraVideoCaptureManager = iONLiveCameraVideoCapture.sharedInstance

    ////PRAGMA MARK:-OutLets
    @IBOutlet var hlsIDPickerView: UIPickerView!
    @IBOutlet var resultsView: UIView!
    @IBOutlet var numberOfSegementsLabel: UILabel!
    @IBOutlet var videoID: UILabel!
    var tField: UITextField!

    var hlsIdDataSource : [String]?
    var selectedHlsId = ""
    
    //PRAGMA MARK:- load View
    override func viewDidLoad() {
        super.viewDidLoad()
        initialiseView()
    }

    //PRAGMA MARK:- Initializers
    func initialiseView()
    {
        resultsView.isHidden = true
        updatePickerDataSource()
    }
    
    //PRAGMA MARK: helper methods
    func updatePickerDataSource()
    {
        let status = IONLiveCameraStatusUtility()
        status.getiONLiveCameraStatus(success: { (response) -> () in
            self.hlsIdDataSource = status.getVideoStatus()
            self.hlsIDPickerView.reloadAllComponents()
            if ((self.hlsIdDataSource?.count)! > 0 )
            {
                self.selectedHlsId = self.hlsIdDataSource![0]
            }
            }) { (error, code) -> () in
                ErrorManager.sharedInstance.alert(title: "error", message: "error")
        }
    }
    
    //PRAGMA MARK:- API calls
    func stopIONLiveCamVideo()
    {
        iONLiveCameraVideoCaptureManager.stopIONLiveCameraVideo(success: { (response) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamGetVideoSuccessHandler(response: response)
            }) { (error, code) -> () in
                self.updatePickerDataSource()
                ErrorManager.sharedInstance.alert(title: "stop Video", message: error?.localizedDescription)
        }
    }

    func startVideoWithSegments(numSegements:Int)
    {
        iONLiveCameraVideoCaptureManager.startVideoWithSegments(numSegments:numSegements, success: { (response) -> () in
            self.updatePickerDataSource()
            ErrorManager.sharedInstance.alert(title: "Updated Video Segements", message: "Successfully Updated Video Segements")
            }) { (error, code) -> () in
                ErrorManager.sharedInstance.alert(title: "Updated Video Segements", message: "Fauilure to Update Video Segements...")
        }
    }
    
    func deleteAllVideo()
    {
        iONLiveCameraVideoCaptureManager.deleteAllVideo(success: { (response) -> () in
            ErrorManager.sharedInstance.alert(title: "Delete Video", message: "Successfully Deleted Video ")
            self.updatePickerDataSource()
            }) { (error, code) -> () in
            self.updatePickerDataSource() //need to remove to test,delete api always fail because it is not valid json
            ErrorManager.sharedInstance.alert(title: "Delete Video", message: error?.localizedDescription)
        }
    }

    func deleteVideoWithHlsId(hlsId:String)
    {
        iONLiveCameraVideoCaptureManager.deleteVideoWithHlsId(hlsID: hlsId, success: { (response) -> () in
            ErrorManager.sharedInstance.alert(title: "Delete Video", message: "Successfully Deleted Video ")
            self.updatePickerDataSource()
            }, failure: { (error, code) -> () in
                self.updatePickerDataSource() //need to remove to test,delete api always fail because it is not valid json
                ErrorManager.sharedInstance.alert(title: "Delete Video", message: error?.localizedDescription)
        })
    }

    func startVideo()
    {
        iONLiveCameraVideoCaptureManager.getiONLiveCameraVideoID(success: { (response) -> () in
            self.updatePickerDataSource()
            self.iONLiveCamGetVideoSuccessHandler(response: response)
            }) { (error, code) -> () in
               ErrorManager.sharedInstance.alert(title: "start Video", message: error?.localizedDescription)
        }
    }

    //PRAGMA MARK:- API Handlers
    func iONLiveCamStopVideoSuccessHandler(response:AnyObject?)
    {
        if (response as? [String: AnyObject]) != nil
        {
            ErrorManager.sharedInstance.alert(title: " Video Stopped", message: "Successfully  Stopped Video")
        }
    }

    func iONLiveCamGetVideoSuccessHandler(response:AnyObject?)
    {
        resultsView.isHidden = false
        if let json = response as? [String: AnyObject]
        {
            if let videoId = json["hlsID"]
            {
                self.videoAPIResult["videoID"] = videoId as? String
                videoID.text =  "videoID = " + videoAPIResult["videoID"]!
            }
            if let numSegments = json["numSegments"]
            {
                let id:String = numSegments as! String
                self.videoAPIResult["numSegments"] = id
                numberOfSegementsLabel.text = "No: of Segements = " + videoAPIResult["numSegments"]!
            }
            if let type = json["Type"]
            {
                let id:String = type as! String
                self.videoAPIResult["type"] = id
            }
        }
    }

    func downLoadm3u8Video()
    {
        iONLiveCameraVideoCaptureManager.downloadm3u8Video(hlsID: videoAPIResult["videoID"]!, success: { (response) -> () in
            ErrorManager.sharedInstance.alert(title: "downloaded m3u8 Video", message: "Successfully downloaded Video ")
            }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "Download Video", message: "Failure to download Video ")
        }
    }

    func configurationTextField(textField: UITextField!)
    {
        textField.placeholder = "Enter number of Segements"
        textField.keyboardType = UIKeyboardType.numberPad
        tField = textField
    }

    func handleCancel(alertView: UIAlertAction!)
    {
    }

    func showAlert()
    {
        let alert = UIAlertController(title: "Enter number of Segements", message: "", preferredStyle: UIAlertControllerStyle.alert)

        alert.addTextField(configurationHandler: configurationTextField)
        alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler:{ (UIAlertAction)in
            if let numSeg = Int(self.tField.text!)
            {
                self.startVideoWithSegments(numSegements: numSeg)
            }
        }))
        self.present(alert, animated: true, completion: {
        })
    }
    
    //PRAGMA MARK:- button Actions
    @IBAction func didTapStartVideo(_ sender: Any) {
        startVideo()
    }

    @IBAction func didTapDeleteAllVideo(_ sender: Any) {
        deleteAllVideo()
    }

    @IBAction func didTapStopVideo(_ sender: Any) {
        stopIONLiveCamVideo()
    }

    @IBAction func didTapDeleteVideoWithID(_ sender: Any) {
       deleteVideoWithHlsId(hlsId: selectedHlsId)
    }
    
    @IBAction func didTapStartVideoWithSegements(_ sender: Any) {
        showAlert()
    }

    @IBAction func didTapDownloadVideo(_ sender: Any) {
        downLoadm3u8Video()
    }

    @IBAction func didTapBackButton(_ sender: Any) {
       _ =  self.navigationController?.popViewController(animated: true)
    }
}

//PRAGMA MARK:- Pickerview delegate datasource
extension iONLiveCamVideoViewController:UIPickerViewDelegate , UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let dataSource = hlsIdDataSource
        {
            return dataSource.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let dataSource = hlsIdDataSource
        {
            return dataSource[row]
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let dataSource = hlsIdDataSource
        {
            selectedHlsId = dataSource[row]
        }
    }
}


