import UIKit
import Vision

enum PhotoAligner {
    struct Alignment {
        let faceCenter: CGPoint
        let eyeDistance: CGFloat
    }

    static func alignment(for image: UIImage) -> Alignment? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try? handler.perform([request])
        guard let face = request.results?.first else { return nil }
        let box = face.boundingBox
        return Alignment(faceCenter: CGPoint(x: box.midX, y: box.midY),
                         eyeDistance: CGFloat(face.landmarks?.leftPupil?.normalizedPoints.count ?? 0))
    }

    static func alignmentOffset(first: UIImage, second: UIImage) -> CGFloat? {
        guard let a = alignment(for: first), let b = alignment(for: second) else { return nil }
        return (a.faceCenter.y - b.faceCenter.y) * second.size.height
    }
}
