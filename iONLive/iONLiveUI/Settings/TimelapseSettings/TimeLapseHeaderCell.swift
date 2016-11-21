
import UIKit

class TimeLapseHeaderCell: UITableViewCell {

    static let identifier = "TimeLapseHeaderCell"
    @IBOutlet weak var bottomBorder: UILabel!
    @IBOutlet weak var topBorder: UILabel!
    @IBOutlet weak var headerTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
