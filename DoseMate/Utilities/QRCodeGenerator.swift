//
//  QRCodeGenerator.swift
//  DoseMate
//
//  Created by bbdyno on 12/10/25.
//

import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Generator

/// QR 코드 생성기
struct QRCodeGenerator {

    // MARK: - Main Generation Method

    /// 문자열을 QR 코드 이미지로 변환
    /// - Parameters:
    ///   - string: QR 코드로 변환할 문자열
    ///   - size: 생성할 이미지 크기 (기본값: 200x200)
    ///   - correctionLevel: 오류 정정 레벨 (L, M, Q, H)
    /// - Returns: QR 코드 UIImage
    static func generate(
        from string: String,
        size: CGSize = CGSize(width: 200, height: 200),
        correctionLevel: CorrectionLevel = .high
    ) -> UIImage {

        guard !string.isEmpty else {
            return placeholderImage(size: size)
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        // QR 코드 데이터 설정
        guard let data = string.data(using: .utf8) else {
            return placeholderImage(size: size)
        }

        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        // QR 코드 이미지 생성
        guard let outputImage = filter.outputImage else {
            return placeholderImage(size: size)
        }

        // 크기 조정
        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let scaledImage = outputImage.transformed(by: transform)

        // CGImage로 변환
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return placeholderImage(size: size)
        }

        return UIImage(cgImage: cgImage)
    }

    /// 암호화폐용 QR 코드 생성 (URI 포맷)
    /// - Parameters:
    ///   - cryptoType: 암호화폐 종류
    ///   - size: 이미지 크기
    /// - Returns: QR 코드 UIImage
    static func generateCrypto(
        for cryptoType: CryptoType,
        size: CGSize = CGSize(width: 250, height: 250)
    ) -> UIImage {
        let uri = cryptoType.qrCodeURI
        return generate(from: uri, size: size, correctionLevel: .high)
    }

    /// URL용 QR 코드 생성
    /// - Parameters:
    ///   - url: URL 문자열
    ///   - size: 이미지 크기
    /// - Returns: QR 코드 UIImage
    static func generateURL(
        _ url: String,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage {
        return generate(from: url, size: size, correctionLevel: .medium)
    }

    // MARK: - Helper Methods

    /// 플레이스홀더 이미지 생성 (에러 발생 시)
    private static func placeholderImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 회색 배경
            UIColor.systemGray5.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // X 표시
            UIColor.systemGray3.setStroke()
            context.cgContext.setLineWidth(2)

            let inset: CGFloat = size.width * 0.25
            context.cgContext.move(to: CGPoint(x: inset, y: inset))
            context.cgContext.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
            context.cgContext.strokePath()

            context.cgContext.move(to: CGPoint(x: size.width - inset, y: inset))
            context.cgContext.addLine(to: CGPoint(x: inset, y: size.height - inset))
            context.cgContext.strokePath()
        }
    }

    // MARK: - Correction Level

    /// QR 코드 오류 정정 레벨
    /// - L: 7% 복원 가능
    /// - M: 15% 복원 가능
    /// - Q: 25% 복원 가능
    /// - H: 30% 복원 가능 (암호화폐용 권장)
    enum CorrectionLevel: String {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI QR 코드 이미지 뷰
struct QRCodeView: View {
    let string: String
    let size: CGSize

    init(_ string: String, size: CGSize = CGSize(width: 200, height: 200)) {
        self.string = string
        self.size = size
    }

    var body: some View {
        Image(uiImage: QRCodeGenerator.generate(from: string, size: size))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
    }
}

/// 암호화폐용 QR 코드 뷰
struct CryptoQRCodeView: View {
    let cryptoType: CryptoType
    let size: CGSize

    init(for cryptoType: CryptoType, size: CGSize = CGSize(width: 250, height: 250)) {
        self.cryptoType = cryptoType
        self.size = size
    }

    var body: some View {
        Image(uiImage: QRCodeGenerator.generateCrypto(for: cryptoType, size: size))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
    }
}

#endif
