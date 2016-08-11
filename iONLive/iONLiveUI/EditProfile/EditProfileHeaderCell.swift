
import UIKit

class EditProfileHeaderCell: UITableViewCell {

    static let identifier = "EditProfileHeaderCell"
    
    @IBOutlet weak var topBorderLine: UILabel!
    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var headerTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
