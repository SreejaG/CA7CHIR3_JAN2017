
import UIKit

class MyChannelItemCell: UICollectionViewCell
{
    static let identifier = "MyChannelItemCell"
    
    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var videoPlayIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
