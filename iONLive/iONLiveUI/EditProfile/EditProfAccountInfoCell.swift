
import UIKit

class EditProfAccountInfoCell: UITableViewCell {
    
   static let identifier = "EditProfAccountInfoCell"

    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var accountInfoTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bringSubviewToFront(borderLine)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
