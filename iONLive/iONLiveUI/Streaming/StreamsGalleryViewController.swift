
import UIKit

class StreamsGalleryViewController: UITabBarController {
    static let identifier = "StreamsGalleryViewController"
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var limit: Int = Int()
    var count: Int = Int()
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.addTabBarItems()
    }
    
    func addTabBarItems()
    {
        NSUserDefaults.standardUserDefaults().objectForKey("SelectedTab")
        self.selectedIndex = NSUserDefaults.standardUserDefaults().integerForKey("SelectedTab")
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
