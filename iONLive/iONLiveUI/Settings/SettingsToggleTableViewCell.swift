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

    @IBAction func changedSwitch(sender: AnyObject) {
        let  settingSwitch = sender as! UISwitch
        self.cellDelegate?.didChangeSwitchState(self, isOn:settingSwitch.on)

    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
