
import UIKit

class TimeTapseCell: UITableViewCell {

    static let identifier = "TimeTapseCell"
    @IBOutlet weak var timelapseOptionLabel: UILabel!
    @IBOutlet weak var selectionImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
