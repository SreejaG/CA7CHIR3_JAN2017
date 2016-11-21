
import UIKit

class EditProfPrivateInfoCell: UITableViewCell,UITextFieldDelegate {
    
   static let identifier = "EditProfPrivateInfoCell"
    
    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var privateInfoTitleLabel: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        privateInfoTitleLabel.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}






