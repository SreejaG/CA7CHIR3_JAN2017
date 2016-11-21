
import UIKit

class ProgramCameraButtonCell: UITableViewCell {

    static let identifier = "ProgramCameraButtonCell"
    @IBOutlet weak var cameraOptionslabel: UILabel!
    @IBOutlet weak var selectionImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
