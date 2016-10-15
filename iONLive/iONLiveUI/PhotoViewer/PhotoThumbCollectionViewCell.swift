
import UIKit

class PhotoThumbCollectionViewCell: UICollectionViewCell,progressviewDelegate {
    
    @IBOutlet weak var playIcon: UIImageView!
    
    @IBOutlet weak var thumbImageView: UIImageView!
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet weak var cloudIcon: UIImageView!
        
    func ProgresviewUpdate (value : Float)
    {
        progressView.progress = value
    }
    
    func toggleSelected (cell :UICollectionViewCell)
    {
        if (selected){
            cell.layer.borderWidth = 10;
            cell.layer.borderColor = UIColor.blueColor().CGColor;
        }else {
            cell.layer.borderColor = UIColor.clearColor().CGColor;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.transform = CGAffineTransformScale(progressView.transform, 1,3)
    }
}
