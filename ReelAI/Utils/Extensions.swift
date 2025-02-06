

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

extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if hexString.hasPrefix("#") {
            scanner.currentIndex = hexString.index(after: hexString.startIndex)
        }
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(color & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
