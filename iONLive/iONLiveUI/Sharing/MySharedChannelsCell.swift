
import UIKit

class MySharedChannelsCell: UITableViewCell {
    
    static let identifier = "MySharedChannelsCell"
    
    @IBOutlet weak var avatarIconImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var sharedCountLabel: UILabel!
    @IBOutlet weak var channelSelectionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func channelSelectionClicked(_ sender: Any)
    {
        let tag = (sender as AnyObject).tag
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshMySharedChannelTableView"), object:tag)
    }
}
