
import Foundation

@objc protocol StreamingProtocol {
    
    func cameraSelectionMode(selection:SnapCamSelectionMode)

    optional func updateStreamingStatus()
}