//
//  UIImage+MLArray.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//



import UIKit
import CoreML
import Vision

extension UIImage {
    func toMLMultiArray224() -> MLMultiArray? {
        // Resize to 224x224 for WoundSnap model
        let targetSize = CGSize(width: 224, height: 224)
        
        guard let resizedImage = self.resized(to: targetSize) else {
            print("❌ Failed to resize image to 224x224")
            return nil
        }
        
        // Convert to RGB pixel buffer
        guard let pixelBuffer = resizedImage.toPixelBuffer(width: 224, height: 224) else {
            print("❌ Failed to convert to pixel buffer")
            return nil
        }
        
        // Create MLMultiArray with CORRECT SHAPE: [1, 224, 224, 3]
        do {
            let inputArray = try MLMultiArray(shape: [1, 224, 224, 3], dataType: .float32)
            
            // Convert pixel buffer to MLMultiArray format
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            
            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
                return nil
            }
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            // Assuming pixel format is 32BGRA (kCVPixelFormatType_32BGRA)
            for y in 0..<height {
                let rowAddress = baseAddress.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
                for x in 0..<width {
                    let pixelOffset = x * 4 // 4 bytes per pixel (BGRA)
                    
                    // Extract BGR channels (skip Alpha)
                    let b = Float(rowAddress[pixelOffset]) / 255.0
                    let g = Float(rowAddress[pixelOffset + 1]) / 255.0
                    let r = Float(rowAddress[pixelOffset + 2]) / 255.0
                    
                    // Calculate indices for NEW shape: [1, 224, 224, 3]
                    // Index calculation: [batch, height, width, channel]
                    let batchIndex = 0
                    let heightIndex = y
                    let widthIndex = x
                    
                    // Calculate flat indices
                    let rIndex = (batchIndex * height * width * 3) + (heightIndex * width * 3) + (widthIndex * 3) + 0
                    let gIndex = (batchIndex * height * width * 3) + (heightIndex * width * 3) + (widthIndex * 3) + 1
                    let bIndex = (batchIndex * height * width * 3) + (heightIndex * width * 3) + (widthIndex * 3) + 2
                    
                    inputArray[rIndex] = NSNumber(value: r)
                    inputArray[gIndex] = NSNumber(value: g)
                    inputArray[bIndex] = NSNumber(value: b)
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            print("✅ Created MLMultiArray with shape [1, 224, 224, 3] - \(inputArray.count) elements")
            return inputArray
            
        } catch {
            print("❌ Failed to create MLMultiArray: \(error)")
            return nil
        }
    }
    
    // Alternative: Vision framework approach (more reliable)
    func predictWithVision(model: WoundSnap) -> (String, Double)? {
        let targetSize = CGSize(width: 224, height: 224)
        
        guard let resizedImage = self.resized(to: targetSize),
              let pixelBuffer = resizedImage.toPixelBuffer(width: 224, height: 224) else {
            print("❌ Failed to prepare image for Vision")
            return nil
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: model.model)
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
            
            if let results = request.results as? [VNClassificationObservation],
               let firstResult = results.first {
                print("✅ Vision prediction: \(firstResult.identifier) - \(firstResult.confidence)")
                return (firstResult.identifier, Double(firstResult.confidence))
            }
        } catch {
            print("❌ Vision error: \(error)")
        }
        
        return nil
    }
    
    // Helper method to resize image
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Convert UIImage to CVPixelBuffer
    func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        return buffer
    }
}
