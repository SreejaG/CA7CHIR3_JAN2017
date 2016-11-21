
import UIKit

class IONCamLiveStreamStatusViewController: UIViewController {
    @IBOutlet weak var liveStreamTableView: UITableView!
    static let identifier = "IONCamLiveStreamStatusViewController"
    let iONLiveStreamStatusManager  = iONCamLiveStatusManager.sharedInstance
    
    var tableViewDataSource = ["FrameRate": ["30","15"],"Resolution":["848x480",
                                                                      "424x240"]]
    
    func getIONLiveStatus( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        iONLiveStreamStatusManager.getiONLiveCameraStatus(success: { (response) -> () in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "Status Failed", message: "Failure to get streaming status ")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func iONLiveCamStreamGetStatusSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            if let liveStreamStatus = json["status"]
            {
                let alertController = UIAlertController(title: "Live Stream Status", message:
                    liveStreamStatus as? String, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func getLiveStreamStatus(_ sender: Any) {
        self.getIONLiveStatus(success: { (response) -> () in
            self.iONLiveCamStreamGetStatusSuccessHandler(response: response)
        }, failure: { (error, code) -> () in
        })
    }
    
    @IBAction func startLiveStreamAction(_ sender: Any) {
    }
}

extension IONCamLiveStreamStatusViewController:UITableViewDelegate,UITableViewDataSource
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
                let cell = tableView.dequeueReusableCell(withIdentifier: StreamPickerTableViewCell.identifier, for: indexPath) as! StreamPickerTableViewCell
                
                cell.inputlabel.text = keys[indexPath.row]
                cell.pickerViewData = values
                cell.selectionStyle = .none
                cell.frameratePickerView.reloadAllComponents()
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

