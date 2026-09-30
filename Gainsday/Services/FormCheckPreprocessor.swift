import UIKit
import Vision

struct PoseCheckResult {
    let isValid: Bool
    let jointCount: Int
    let joints: [CGPoint]
    let message: String
}

enum FormCheckPreprocessor {
    static func validate(_ image: UIImage) -> PoseCheckResult {
        guard let cgImage = image.cgImage else {
            return PoseCheckResult(isValid: false, jointCount: 0, joints: [], message: "Could not read the image. Try again.")
        }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try? handler.perform([request])
        guard let observation = request.results?.first,
              let points = try? observation.recognizedPoints(.all) else {
            return PoseCheckResult(isValid: false, jointCount: 0, joints: [], message: "No person detected. Try a wider side view.")
        }
        let confident = points.values.filter { $0.confidence > 0.3 }
        let joints = confident.map { CGPoint(x: $0.location.x, y: $0.location.y) }
        if confident.count < 8 {
            return PoseCheckResult(isValid: false, jointCount: confident.count, joints: joints,
                                   message: "Body not fully visible. Step back and retake from the side.")
        }
        return PoseCheckResult(isValid: true, jointCount: confident.count, joints: joints, message: "")
    }

    static func annotatedImage(_ image: UIImage, joints: [CGPoint]) -> UIImage {
        guard !joints.isEmpty else { return image }
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            ctx.cgContext.setFillColor(UIColor.systemOrange.cgColor)
            for j in joints {
                let rect = CGRect(x: j.x * size.width - 4, y: (1 - j.y) * size.height - 4, width: 8, height: 8)
                ctx.cgContext.fillEllipse(in: rect)
            }
        }
    }

    static func compressed(_ image: UIImage, maxSide: CGFloat = 768) -> Data? {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: target).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        var quality: CGFloat = 0.7
        var data = resized.jpegData(compressionQuality: quality)
        while let d = data, d.count > 512 * 1024, quality > 0.3 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality)
        }
        return data
    }
}
