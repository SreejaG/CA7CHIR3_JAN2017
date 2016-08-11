
import UIKit

class EditProfPrivateInfoCell: UITableViewCell,UITextFieldDelegate {
    
   static let identifier = "EditProfPrivateInfoCell"
    
    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var privateInfoTitleLabel: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        privateInfoTitleLabel.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    func textFieldDidEndEditing(textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}






