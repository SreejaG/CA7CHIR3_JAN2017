
import UIKit

class SimpleTextFieldTableViewCell: UITableViewCell {

    static let identifier = "SimpleTextFieldTableViewCell"
    @IBOutlet var inputTextField: UITextField!
    @IBOutlet var inputLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
