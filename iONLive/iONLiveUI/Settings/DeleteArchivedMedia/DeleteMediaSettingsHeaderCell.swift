
import UIKit

class DeleteMediaSettingsHeaderCell: UITableViewCell {

    static let identifier = "DeleteMediaSettingsHeaderCell"
    
    @IBOutlet weak var topBorder: UILabel!
    @IBOutlet weak var bottomBorder: UILabel!
    @IBOutlet weak var headerTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
