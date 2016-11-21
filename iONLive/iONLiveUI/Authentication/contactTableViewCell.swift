
import UIKit

class contactTableViewCell: UITableViewCell {
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactProfileName: UILabel!
    @IBOutlet var contactSelectionButton: UIButton!
    
    var section : Int = Int()
    
    @IBAction func contactSelectionButtonClicked(_ sender: Any) {
        let tag = (sender as AnyObject).tag
        let dict = ["sectionKey": section,"rowKey":tag]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSignUpContactListTableView"), object:dict)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
