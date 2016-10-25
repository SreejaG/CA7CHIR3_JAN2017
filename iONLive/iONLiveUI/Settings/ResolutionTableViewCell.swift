
import UIKit

class ResolutionTableViewCell: UITableViewCell {
    
    static let identifier = "ResolutionTableViewCell"
    
    @IBOutlet var resolutionLabel: UILabel!
    @IBOutlet weak var selectionImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
