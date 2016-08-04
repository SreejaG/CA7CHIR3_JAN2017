
import UIKit

class contactSharingDetailTableViewCell: UITableViewCell {
    
    static let identifier = "contactSharingDetailTableViewCell"
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    @IBOutlet var subscriptionButton: UIButton!
    
    @IBAction func contactSharingButtonClicked(sender: AnyObject) {
            let tag = sender.tag
        NSNotificationCenter.defaultCenter().postNotificationName("refreshContactSharingTableView", object:tag)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true     
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
