
import UIKit

class ChannelItemListCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ChannelItemListCollectionViewCell"
    @IBOutlet weak var channelItemImageView: UIImageView!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var tickButton: UIButton!
    @IBOutlet var videoView: UIView!
    @IBOutlet var videoPlayIcon: UIImageView!
    @IBOutlet var videoDurationLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
