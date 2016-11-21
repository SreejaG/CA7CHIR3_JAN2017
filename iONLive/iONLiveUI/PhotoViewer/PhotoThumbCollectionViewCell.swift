
import UIKit

class PhotoThumbCollectionViewCell: UICollectionViewCell,progressviewDelegate {
    
    @IBOutlet weak var playIcon: UIImageView!
    
    @IBOutlet weak var thumbImageView: UIImageView!
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet weak var cloudIcon: UIImageView!
        
    @IBOutlet var reloadMedia: UIImageView!
    func ProgresviewUpdate (value : Float)
    {
        progressView.progress = value
    }
    
    func toggleSelected (cell :UICollectionViewCell)
    {
        if (isSelected){
            cell.layer.borderWidth = 10;
            cell.layer.borderColor = UIColor.blue.cgColor;
        }else {
            cell.layer.borderColor = UIColor.clear.cgColor;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.transform = progressView.transform.scaledBy(x: 1,y: 3)
    }
}
