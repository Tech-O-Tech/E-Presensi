//
//  ImageCompressor.swift
//  E-Presensi
//

import UIKit

enum ImageCompressor {
    /// Setara compressFile Android — JPEG ~80%, max lebar 1024px
    static func compress(_ image: UIImage, maxWidth: CGFloat = 1024, quality: CGFloat = 0.8) -> Data? {
        let scaled = resize(image, maxWidth: maxWidth)
        return scaled.jpegData(compressionQuality: quality)
    }

    static func resize(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        guard image.size.width > maxWidth else { return image }
        let scale = maxWidth / image.size.width
        let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
