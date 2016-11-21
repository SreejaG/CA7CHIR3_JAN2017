
import UIKit

class StreamPickerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var frameratePickerView: UIPickerView!
    static let identifier = "StreamPickerTableViewCell"
    var pickerViewData : [String] = [String]()
    @IBOutlet weak var inputlabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

//PRAGMA MARK:- Pickerview delegate datasource
extension StreamPickerTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource
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
        _ = pickerViewData[pickerView.selectedRow(inComponent: 0)]
    }
}
