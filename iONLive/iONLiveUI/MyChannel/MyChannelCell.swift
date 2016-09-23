
import UIKit

class MyChannelCell: UITableViewCell {

    static let identifier = "MyChannelCell"
    @IBOutlet weak var channelHeadImageView: UIImageView!
    @IBOutlet weak var channelItemCount: UILabel!
    @IBOutlet weak var channelNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        channelNameLabel.numberOfLines = 1
        channelNameLabel.minimumScaleFactor = 0.5
        channelNameLabel.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
