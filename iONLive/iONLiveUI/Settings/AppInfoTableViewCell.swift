
import UIKit

class AppInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var accessryLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "AppInfoTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
