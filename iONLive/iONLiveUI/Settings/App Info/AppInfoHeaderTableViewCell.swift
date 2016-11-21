
import UIKit

class AppInfoHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var topBorder: UILabel!
    @IBOutlet weak var bottomBorder: UILabel!
    @IBOutlet weak var headerTitleLabel: UILabel!
    
    static let identifier = "AppInfoHeaderTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
