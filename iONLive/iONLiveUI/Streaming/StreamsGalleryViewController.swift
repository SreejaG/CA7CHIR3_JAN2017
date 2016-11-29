
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.addTabBarItems()
    }
    
    func addTabBarItems()
    {
        UserDefaults.standard.object(forKey: "SelectedTab")
        self.selectedIndex = UserDefaults.standard.integer(forKey: "SelectedTab")
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
