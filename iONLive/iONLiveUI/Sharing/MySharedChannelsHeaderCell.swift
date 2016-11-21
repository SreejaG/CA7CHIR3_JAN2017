
import UIKit

class MySharedChannelsHeaderCell: UITableViewCell {
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    static let identifier = "MySharedChannelsHeaderCell"
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
