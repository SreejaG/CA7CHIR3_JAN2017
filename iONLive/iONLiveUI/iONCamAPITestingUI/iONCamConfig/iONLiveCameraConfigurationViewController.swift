
import UIKit

class iONLiveCameraConfigurationViewController: UIViewController {
    
    static let identifier = "iONLiveCameraConfigurationViewController"
    
    @IBOutlet var inputSingleClickTextField: UITextField!
    @IBOutlet var inputDoubleClickTextField: UITextField!
    @IBOutlet var inputScaleTextField: UITextField!
    @IBOutlet var inputQualityTextField: UITextField!
    
    @IBOutlet var outputSingleClickTextField: UITextField!
    @IBOutlet var outputDoubleClickTextField: UITextField!
    @IBOutlet var outputScaleTextField: UITextField!
    @IBOutlet var outputQualityTextField: UITextField!
    
    @IBOutlet var outPutView: UIView!
    
    //PRAGMA MARK:- class variables
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraConfigManager = iONLiveCameraConfiguration.sharedInstance
    
    //PRAGMA MARK:- loadView
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        inputSingleClickTextField.text = ""
        inputDoubleClickTextField.text = ""
        inputQualityTextField.text = ""
        inputScaleTextField.text = ""
        
        outPutView.isHidden = true
    }
    
    //PRAGMA MARK:- API Handler
    func iONLiveCamGetConfigSuccessHandler(response:AnyObject?)
    {
        outPutView.isHidden = false
        if let json = response as? [String: AnyObject]
        {
            if let quality = json["quality"]
            {
                let intVal = quality as! Int
                let stringVal = String(intVal)
                outputQualityTextField.text =  stringVal
            }
            if let scale = json["scale"]
            {
                let intVal = scale as! Int
                let stringVal = String(intVal)
                outputScaleTextField.text = stringVal
            }
            if let singleClick = json["singleClick"]
            {
                outputSingleClickTextField.text = singleClick as? String
            }
            if let doubleClick = json["doubleClick"]
            {
                outputDoubleClickTextField.text = doubleClick as? String
            }
        }
    }
    
    @IBAction func didTapPutCameraConfiguration(_ sender: Any) {
        self.view.endEditing(true)
        iONLiveCameraConfigManager.putIONLiveCameraConfiguration(scale: inputScaleTextField.text, quality: inputQualityTextField.text, singleClick: inputSingleClickTextField.text, doubleClick: inputDoubleClickTextField.text, success: { (response) -> () in
            self.iONLiveCamGetConfigSuccessHandler(response: response)
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "Config Failed", message: "Failure to get config ")
        }
    }
    
    @IBAction func didTapGetCameraConfiguration(_ sender: Any) {
        self.view.endEditing(true)
        
        iONLiveCameraConfigManager.getiONLiveCameraConfiguration(scale: inputScaleTextField.text, quality: inputQualityTextField.text, singleClick: inputSingleClickTextField.text, doubleClick: inputDoubleClickTextField.text, success: { (response) -> () in
            self.iONLiveCamGetConfigSuccessHandler(response: response)
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "Config Failed", message: "Failure to get config ")
        }
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
