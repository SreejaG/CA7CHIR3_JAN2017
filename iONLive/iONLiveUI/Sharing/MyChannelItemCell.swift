
import UIKit

class MyChannelItemCell: UICollectionViewCell
{
    static let identifier = "MyChannelItemCell"
    
    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var videoPlayIcon: UIImageView!
    @IBOutlet var videoDurationLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
