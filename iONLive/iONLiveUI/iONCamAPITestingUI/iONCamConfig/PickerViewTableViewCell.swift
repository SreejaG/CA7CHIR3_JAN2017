//
//  PickerViewTableViewCell.swift
//  iONLive
//
//  Created by Vinitha on 2/5/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class PickerViewTableViewCell: UITableViewCell {

    static let identifier = "PickerViewTableViewCell"
    @IBOutlet var inputPickerView: UIPickerView!
    @IBOutlet var inputLabel: UILabel!
    var pickerViewData : [String] = [String]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

//PRAGMA MARK:- Pickerview delegate datasource

extension PickerViewTableViewCell:UIPickerViewDelegate , UIPickerViewDataSource
{
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickerViewData.count
        
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pickerViewData[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        var selectRow = pickerViewData[row]
        var selectedSource = inputLabel.text;
    }
}
