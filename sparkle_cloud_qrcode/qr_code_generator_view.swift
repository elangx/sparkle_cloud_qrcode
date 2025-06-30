//
//  qr_code_generator_view.swift
//  sparkle_cloud_qrcode
//
//  Created by Ethan on 2025/6/30.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

#Preview {
    QRCodeGeneratorView()
}

struct QRCodeGeneratorView: View {
    // QR码生成状态
    @State private var inputText: String = "https://www.apple.com"
    @State private var qrCodeImage: UIImage?
    @State private var qrCodePixels: [[Bool]] = []
    @State private var qrCodeSize: CGSize = .zero
    @State private var isPlaying = false
    @State private var frameRate: Double = 2.0
    @State private var timer: Timer? = nil
    @State private var currentImageIndex = 0
    @State private var qrCodeImages: [UIImage] = []
    
    // 错误纠正级别
    @State private var errorCorrectionLevel: String = "M"
    let errorCorrectionLevels = ["L": "低 (7%)", "M": "中 (15%)", "Q": "高 (25%)", "H": "最高 (30%)"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                
                // QR码显示区域
                VStack {
                    if let qrCodeImage = qrCodeImage {
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else {
                        Text("QR码将在此显示")
                            .frame(width: 300, height: 300)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 输入区域
                VStack(alignment: .leading) {
                    Text("输入文本生成QR码")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.vertical, 5)
                    
                    HStack {
                        Picker("纠错级别:", selection: $errorCorrectionLevel) {
                            ForEach(errorCorrectionLevels.keys.sorted(), id: \.self) { key in
                                Text("\(errorCorrectionLevels[key] ?? "")").tag(key)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.trailing)
                        
                        Button("生成QR码") {
                            generateQRCode()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

            }
            .padding()
        }
    }
    
    // 计算黑点数量
    private var blackPixelCount: Int {
        qrCodePixels.flatMap { $0 }.filter { $0 }.count
    }
    
    // 生成QR码
    private func generateQRCode() {
        guard !inputText.isEmpty else { return }
        
        // 创建QR码过滤器
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // 设置内容
        let data = Data(inputText.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // 设置错误纠正级别
        filter.setValue(errorCorrectionLevel, forKey: "inputCorrectionLevel")
        
        // 生成QR码图像
        guard let outputImage = filter.outputImage else { return }
        
        // 转换为UIImage
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            qrCodeImage = UIImage(cgImage: cgImage)
            
            // 分析像素数据
            analyzeQRCodePixels(image: qrCodeImage!)
        }
    }
    
    // 分析QR码像素
    private func analyzeQRCodePixels(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        // 获取图像尺寸
        let width = cgImage.width
        let height = cgImage.height
        qrCodeSize = CGSize(width: width, height: height)
        
        // 创建像素数组
        var pixels = [[Bool]](repeating: [Bool](repeating: false, count: width), count: height)
        
        // 获取像素数据
        guard let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return
        }
        
        // 遍历每个像素
        for y in 0..<height {
            for x in 0..<width {
                let pixelInfo = (width * y + x) * 4
                
                // 获取RGB值
                let r = data[pixelInfo]
                let g = data[pixelInfo + 1]
                let b = data[pixelInfo + 2]
                
                // 判断是否为黑色（简单阈值法）
                let isBlack = (r < 100) && (g < 100) && (b < 100)
                pixels[y][x] = isBlack
            }
        }
        
        qrCodePixels = pixels
    }
    
    
    // 创建交替播放图像
    private func createAlternatingImages() {
        guard !qrCodePixels.isEmpty else { return }
        
        let width = Int(qrCodeSize.width)
        let height = Int(qrCodeSize.height)
        
        // 创建图像1：QR码原始图像
        var image1Data = [UInt8]()
        for y in 0..<height {
            for x in 0..<width {
                if qrCodePixels[y][x] {
                    // 黑色
                    image1Data.append(0)   // R
                    image1Data.append(0)   // G
                    image1Data.append(0)   // B
                    image1Data.append(255) // A
                } else {
                    // 白色
                    image1Data.append(255) // R
                    image1Data.append(255) // G
                    image1Data.append(255) // B
                    image1Data.append(255) // A
                }
            }
        }
        
        // 创建图像2：反转图像
        var image2Data = [UInt8]()
        for y in 0..<height {
            for x in 0..<width {
                if qrCodePixels[y][x] {
                    // 原始为黑色 -> 变为白色
                    image2Data.append(255) // R
                    image2Data.append(255) // G
                    image2Data.append(255) // B
                    image2Data.append(255) // A
                } else {
                    // 原始为白色 -> 变为黑色
                    image2Data.append(0)   // R
                    image2Data.append(0)   // G
                    image2Data.append(0)   // B
                    image2Data.append(255) // A
                }
            }
        }
        
        // 生成UIImage
        if let image1 = createImage(from: image1Data, width: width, height: height) {
            qrCodeImages = [image1]
        }
        
        if let image2 = createImage(from: image2Data, width: width, height: height) {
            qrCodeImages.append(image2)
        }
    }
    
    // 创建UIImage
    private func createImage(from pixelData: [UInt8], width: Int, height: Int) -> UIImage? {
        guard pixelData.count == width * height * 4 else {
            print("像素数据大小不匹配")
            return nil
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let providerRef = CGDataProvider(data: Data(pixelData) as CFData) else {
            return nil
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

