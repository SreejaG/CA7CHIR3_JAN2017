
import UIKit

class ContactListTableViewCell: UITableViewCell {

    static let identifier = "ContactListTableViewCell"
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    @IBOutlet var subscriptionButton: UIButton!
    
    var loadingOverlay: UIView?
    
    @IBAction func contactSharingButtonClicked(_ sender: Any) {
        let tag = (sender as AnyObject).tag
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshContactListTableView"), object:tag)
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
