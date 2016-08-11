
import UIKit

class contactTableViewCell: UITableViewCell {
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactProfileName: UILabel!
    @IBOutlet var contactSelectionButton: UIButton!
    
    var section : Int = Int()
    
    @IBAction func contactSelectionButtonClicked(sender: AnyObject) {
        let tag = sender.tag
        let dict = ["sectionKey": section,"rowKey":tag]
        NSNotificationCenter.defaultCenter().postNotificationName("refreshSignUpContactListTableView", object:dict)
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
