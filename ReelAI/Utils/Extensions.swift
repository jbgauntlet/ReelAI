

import UIKit

extension UILabel {
    func setTextWithLetterSpacing(_ text: String, spacing: CGFloat) {
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: text.count))
        self.attributedText = attributedString
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func resizeWithHeight(to newHeight: CGFloat) -> UIImage? {
        let oldWidth = self.size.width
        let oldHeight = self.size.height
        let ratio = newHeight / oldHeight
        let newWidth = ratio * oldWidth
        return resized(to: CGSize(width: newWidth, height: newHeight))
    }
    
    func resizeWithWidth(to newWidth: CGFloat) -> UIImage? {
        let oldWidth = self.size.width
        let oldHeight = self.size.height
        let ratio = newWidth / oldWidth
        let newHeight = ratio * oldHeight
        return resized(to: CGSize(width: newWidth, height: newHeight))
    }
}
