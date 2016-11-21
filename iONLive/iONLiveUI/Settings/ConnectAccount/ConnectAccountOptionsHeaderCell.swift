
import UIKit

class ConnectAccountOptionsHeaderCell: UITableViewCell {

    static let identifier = "ConnectAccountOptionsHeaderCell"
    @IBOutlet weak var topBorder: UILabel!
    @IBOutlet weak var bottomBorder: UILabel!
    @IBOutlet weak var headerTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
