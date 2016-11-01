
import UIKit

class Ca7chContactsTableViewCell: UITableViewCell {

    static let identifier = "Ca7chContactsTableViewCell"
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    @IBOutlet var subscriptionButton: UIButton!
    @IBOutlet var profileDownloadIndicator: UIActivityIndicatorView!
    
    var section : Int = Int()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func Ca7chContactsSharingButtonClicked(sender: AnyObject) {
        let tag = sender.tag
        let dict = ["sectionKey": section,"rowKey":tag]
        NSNotificationCenter.defaultCenter().postNotificationName("refreshCa7chContactsListTableView", object:dict)
    }

}
