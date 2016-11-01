
import UIKit

class phoneContactsTableViewCell: UITableViewCell {

    static let identifier = "phoneContactsTableViewCell"

    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    @IBOutlet var subscriptionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func phoneContactsSharingButtonClicked(sender: AnyObject) {
        let tag = sender.tag
        NSNotificationCenter.defaultCenter().postNotificationName("refreshphoneContactsListTableView", object:tag)
    }
}
