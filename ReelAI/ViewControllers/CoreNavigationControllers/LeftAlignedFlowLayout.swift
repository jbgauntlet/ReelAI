

import UIKit

// Custom Flow Layout to ensure left alignment and constant spacing
class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        for layoutAttribute in attributes {
            // Check if we're on a new row
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            // Adjust the frame to start at the leftMargin and move items along horizontally
            layoutAttribute.frame.origin.x = leftMargin
            
            // Update leftMargin for the next item
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            
            // Keep track of the maximum Y coordinate (to detect new rows)
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
