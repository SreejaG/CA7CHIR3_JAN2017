//
//  StreamPickerTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon on 2/10/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class StreamPickerTableViewCell: UITableViewCell {

    @IBOutlet weak var frameratePickerView: UIPickerView!
    static let identifier = "StreamPickerTableViewCell"
    var pickerViewData : [String] = [String]()
    
    @IBOutlet weak var inputlabel: UILabel!
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

extension StreamPickerTableViewCell:UIPickerViewDelegate , UIPickerViewDataSource
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
        let selectedValue = pickerViewData[pickerView.selectedRowInComponent(0)]
        print(selectedValue)
    }
 
 
}
