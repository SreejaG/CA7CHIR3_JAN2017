
import UIKit

class EditProfPersonalInfoCell: UITableViewCell,UITextFieldDelegate {
    
   static let identifier = "EditProfPersonalInfoCell"

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    
    @IBOutlet var editProfileImageButton: UIButton!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        userNameTextField.delegate = self
        displayNameTextField.delegate = self
        displayNameTextField.autocorrectionType = .no
        userImage.layer.cornerRadius = userImage.frame.size.width/2
        userImage.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
       textField.layoutIfNeeded()
    }
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
