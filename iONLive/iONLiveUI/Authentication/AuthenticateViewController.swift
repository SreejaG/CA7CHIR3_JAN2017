
import UIKit

class AuthenticateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        customise()

        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func customise()
    {
        if #available(iOS 8.2, *) {
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular),NSForegroundColorAttributeName: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)]
        }
        else if #available(iOS 8.1, *)
        {
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue-Thin", size: 18)!,NSForegroundColorAttributeName: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)]
        }
        else
        {
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue-Regular", size: 18)!,NSForegroundColorAttributeName: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)]
        }
        
        UINavigationBar.appearance().tintColor = UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()
    }
}
