
import Foundation
class IONLLoadingView: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func startLoading(){
        activityIndicator.startAnimating()
    }
    
    func stopLoading(){
        activityIndicator.stopAnimating()
    }
}
