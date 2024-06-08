import UIKit

extension UIImage {
    func resize(toWidth width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: width, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}


func processImage(selectedImage: UIImage, targetWidth: CGFloat = 1200, compressionQuality: CGFloat = 0.8) -> UIImage? {
    guard let resizedImage = selectedImage.resize(toWidth: targetWidth) else {
        print("Failed to resize image")
        return nil
    }
    
    guard let compressedImageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
        print("Failed to compress image")
        return nil
    }
    
    guard let compressedImage = UIImage(data: compressedImageData) else {
        print("Failed to create UIImage from compressed data")
        return nil
    }
    
    return compressedImage
}
