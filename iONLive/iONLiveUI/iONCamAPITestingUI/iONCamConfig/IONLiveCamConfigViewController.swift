
import UIKit

class IONLiveCamConfigViewController: UIViewController {
    
    static let identifier = "IONLiveCamConfigViewController"
    
    @IBOutlet var cameraConfigTableView: UITableView!
    
    //PRAGMA MARK: - DataSource
    var tableViewDataSource = ["Video Resolution": ["3840x2160","1920x1080","1280x720","848x480"],"ButtonSingleClick":["Picture"],"videoFps":["240","200","120","100","60","50","30","25"],"buttonDoubleClick":["video"],"led":["on"],"quality":["1","2","3"],"scale":["1","2","4","8"]]
    
    //PRAGMA MARK:- class variables
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraConfigManager = iONLiveCameraConfiguration.sharedInstance
    
    //PRAGMA MARK:- loadView
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    //PRAGMA MARK:- API Handler
    
    func iONLiveCamGetConfigSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            if json["quality"] != nil
            {
            }
            if json["scale"] != nil
            {
            }
            if json["singleClick"] != nil
            {
            }
            if json["doubleClick"] != nil
            {
            }
        }
    }
    
    @IBAction func didTapPutCameraConfiguration(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func didTapGetCameraConfiguration(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func createPickerViewTableViewCell()
    {
        
    }
}

extension IONLiveCamConfigViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableViewDataSource.count > indexPath.row
        {
            var keys = Array(tableViewDataSource.keys)
            let values:Array = tableViewDataSource[keys[indexPath.row]]!
            
            if values.count > 1
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: PickerViewTableViewCell.identifier, for: indexPath) as! PickerViewTableViewCell
                
                cell.inputLabel.text = keys[indexPath.row]
                cell.pickerViewData = values
                cell.selectionStyle = .none
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTextFieldTableViewCell.identifier, for: indexPath) as! SimpleTextFieldTableViewCell
                cell.inputLabel.text = keys[indexPath.row]
                cell.inputTextField.text = values[0]
                cell.selectionStyle = .none
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//TextField Delegate
extension IONLiveCamConfigViewController:UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
