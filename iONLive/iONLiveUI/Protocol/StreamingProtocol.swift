
import Foundation

@objc protocol StreamingProtocol {
    
    @objc optional func cameraSelectionMode(selection:SnapCamSelectionMode)

    @objc optional func updateStreamingStatus()
}
