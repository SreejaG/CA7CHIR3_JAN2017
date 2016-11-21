
import UIKit

protocol toggleCellDelegate : class {
    func didChangeSwitchState(toggleCell: SettingsToggleTableViewCell, isOn: Bool)
}
class SettingsToggleTableViewCell: UITableViewCell {

    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var toggleCellSwitch: UISwitch!
    weak var cellDelegate: toggleCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func changedSwitch(_ sender: Any) {
        let  settingSwitch = sender as! UISwitch
        self.cellDelegate?.didChangeSwitchState(toggleCell: self, isOn:settingSwitch.isOn)

    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
