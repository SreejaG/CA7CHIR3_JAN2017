
import UIKit

class iONCamPictureAPIResultViewController: UIViewController {
    
   static let identifier = "iONCamPictureAPIResultViewController"
    
    var imageBurstId:String = ""
    @IBOutlet weak var resultImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(imageBurstId != "")
        {
            let urlChkStr = UrlManager.sharedInstance.getiONLiveCamImageDownloadUrl(burstId: imageBurstId)
            let urlChk : URL = convertStringtoURL(url: urlChkStr) as URL
            resultImageView.setImageWith(urlChk)
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }

    @IBAction func didTapBackButton(_ sender: Any) {
       _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
