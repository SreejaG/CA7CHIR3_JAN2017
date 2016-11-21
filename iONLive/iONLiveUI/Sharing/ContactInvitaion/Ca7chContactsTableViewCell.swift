
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func Ca7chContactsSharingButtonClicked(_ sender: Any) {
        let tag = (sender as AnyObject).tag
        let dict = ["sectionKey": section,"rowKey":tag]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshCa7chContactsListTableView"), object:dict)
    }
}
