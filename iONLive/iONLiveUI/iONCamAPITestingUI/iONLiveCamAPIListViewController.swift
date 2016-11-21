
import UIKit

class iONLiveCamAPIListViewController: UIViewController {
    
    @IBOutlet weak var testingAPIListTableView: UITableView!
    static let identifier = "iONLiveCamAPIListViewController"
    
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraVideoCaptureManager = iONLiveCameraVideoCapture.sharedInstance
    
    var wifiButtonSelected = true
    var dataSource:[String]?
    
    var wifiAPIList = ["Image capture","Video capture","Camera configuration","Live streaming configuration","Cloud connectivity configuration","Camera status","System information and modification","Download Image file","Download HLS playlist","Download video file","Download HLS segment"]
    
    var bleAPIList = [""]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if wifiButtonSelected
        {
            dataSource = wifiAPIList
        }
        else
        {
            dataSource = bleAPIList
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func backButtonClicked(_ sender: Any)
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func wifiButtonClicked(_ sender: Any)
    {
        wifiButtonSelected = true
        dataSource = wifiAPIList
        testingAPIListTableView.reloadData()
    }
    
    @IBAction func bleButtonClicked(_ sender: Any)
    {
        wifiButtonSelected = false
        dataSource = bleAPIList
        testingAPIListTableView.reloadData()
    }
}

extension iONLiveCamAPIListViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource != nil ? (dataSource!.count) :0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                let cell = UITableViewCell(style:.default, reuseIdentifier:"Cell")
                cell.textLabel?.text = dataSource[indexPath.row]
                cell.selectionStyle = .none
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row
        {
        case 0:
            loadPictureAPIViewController()
            break;
        case 1:
            loadIONLiveCamVideo()
            break;
        case 2:
            loadCameraConfiguration()
        case 3:
            loadLiveStreamStatus()
        case 5:
            loadCameraStatus()
        default:
            break;
        }
    }
}

//PRAGMA MARK:- load test API views
extension iONLiveCamAPIListViewController{
    
    func loadPictureAPIViewController()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let pictureApiVC = apiTestStoryboard.instantiateViewController(withIdentifier: iONCamPictureAPIViewController.identifier) as! iONCamPictureAPIViewController
        self.navigationController?.pushViewController(pictureApiVC, animated: true)
    }
    
    func getVideoAPIViewController() -> iONLiveCamVideoViewController
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let videoApiVC = apiTestStoryboard.instantiateViewController(withIdentifier: iONLiveCamVideoViewController.identifier) as! iONLiveCamVideoViewController
        return videoApiVC
    }
    
    func loadCameraStatus()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewController(withIdentifier: iONLiveCameraStatusViewController.identifier) as! iONLiveCameraStatusViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
    
    func loadCameraConfiguration()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewController(withIdentifier: IONLiveCamConfigViewController.identifier) as! IONLiveCamConfigViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
    
    func loadLiveStreamStatus()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewController(withIdentifier: IONCamLiveStreamStatusViewController.identifier) as! IONCamLiveStreamStatusViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
    
    //PRAGMA MARK:- Test API call
    func loadIONLiveCamVideo()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewController(withIdentifier: iONLiveCamVideoViewController.identifier) as! iONLiveCamVideoViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
}


