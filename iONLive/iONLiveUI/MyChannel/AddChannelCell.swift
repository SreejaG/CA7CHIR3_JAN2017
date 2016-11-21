
import UIKit

class AddChannelCell: UITableViewCell {

    static let identifier = "AddChannelCell"
    
    @IBOutlet var addChannelImageView: UIImageView!
    @IBOutlet var addChannelTextLabel: UILabel!
    @IBOutlet var addChannelCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
