

import Foundation
import UIKit

class CustomView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        print("Touched view: \(view)")
        return view
    }
}
