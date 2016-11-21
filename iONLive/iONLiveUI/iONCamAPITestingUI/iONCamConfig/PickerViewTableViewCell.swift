
import UIKit

class PickerViewTableViewCell: UITableViewCell {
    
    static let identifier = "PickerViewTableViewCell"
    @IBOutlet var inputPickerView: UIPickerView!
    @IBOutlet var inputLabel: UILabel!
    var pickerViewData : [String] = [String]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

//PRAGMA MARK:- Pickerview delegate datasource
extension PickerViewTableViewCell:UIPickerViewDelegate , UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerViewData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerViewData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
}

