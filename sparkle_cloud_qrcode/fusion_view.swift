//
//  fusion_view.swift
//  sparkle_cloud_qrcode
//
//  Created by Ethan on 2025/6/30.
//

import SwiftUI

struct FinalView: View {
    // 图片尺寸
    let imageSize = CGSize(width: 256, height: 256)
    
    // 状态管理
    @State private var currentImageIndex = 0
    @State private var isPlaying = false
    @State private var frameRate: Double = 2.0
    @State private var timer: Timer? = nil
    
    // 自定义像素数据
    @State private var pixelData1: [UInt8] = []
    @State private var pixelData2: [UInt8] = []
    @State private var images: [UIImage] = []
    
    // 当前编辑的图片索引
    @State private var editingImageIndex = 0
    
    // 颜色选择器状态
    @State private var selectedColor: Color = .blue
    @State private var selectedPosition: CGPoint = .zero
    
    var body: some View {
        ScrollView {
            VStack {
                // 图片显示区域
                if !images.isEmpty {
                    Image(uiImage: images[currentImageIndex])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.1), value: currentImageIndex)
                        .overlay(
                            GeometryReader { geometry in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let location = value.location
                                                let viewSize = geometry.size
                                                let x = max(0, min(1, Double(location.x / viewSize.width)))
                                                let y = max(0, min(1, Double(location.y / viewSize.height)))
                                                selectedPosition = CGPoint(x: x, y: y)
                                            }
                                    )
                            }
                        )
                } else {
                    Text("生成图像中...")
                        .frame(width: 300, height: 300)
                        .padding()
                }
                
                // 图像信息
                if !images.isEmpty {
                    Text("当前图像: \(currentImageIndex + 1)")
                        .font(.headline)
                        .padding(.top)
                }
                
                // 像素编辑控制
                VStack {
                    Text("像素编辑")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack {
                        Button("图片1") { editingImageIndex = 0 }
                            .padding()
                            .background(editingImageIndex == 0 ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                        
                        Button("图片2") { editingImageIndex = 1 }
                            .padding()
                            .background(editingImageIndex == 1 ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                    
                    ColorPicker("选择颜色", selection: $selectedColor)
                        .padding()
                    
                    Button("应用颜色到当前位置") {
                        applyColorToPosition()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("随机生成图片") {
                        generateRandomImages()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 帧率控制
                VStack(alignment: .leading) {
                    Text("帧率: \(String(format: "%.1f", frameRate)) FPS")
                        .font(.headline)
                    
                    Slider(value: $frameRate, in: 0.5...60.0, step: 0.5) {
                        Text("帧率")
                    } minimumValueLabel: {
                        Text("0.5")
                    } maximumValueLabel: {
                        Text("60")
                    }
                    .padding(.vertical)
                    .onChange(of: frameRate) { _ in
                        restartTimer()
                    }
                }
                .padding()
                
                // 控制按钮
                HStack(spacing: 30) {
                    Button(action: togglePlay) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(isPlaying ? .red : .green)
                    }
                    
                    Button(action: reset) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .onAppear {
                generateRandomImages()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // 生成随机图像
    private func generateRandomImages() {
        pixelData1 = generateRandomPixelData()
        pixelData2 = generateRandomPixelData()
        
        if let image1 = createImage(from: pixelData1) {
            images = [image1]
        }
        
        if let image2 = createImage(from: pixelData2) {
            images.append(image2)
        }
    }
    
    // 生成随机像素数据
    private func generateRandomPixelData() -> [UInt8] {
        var data = [UInt8]()
        let pixelCount = Int(imageSize.width * imageSize.height)
        
        for _ in 0..<pixelCount {
            data.append(UInt8.random(in: 0...255)) // R
            data.append(UInt8.random(in: 0...255)) // G
            data.append(UInt8.random(in: 0...255)) // B
            data.append(255) // Alpha (不透明)
        }
        
        return data
    }
    
    // 创建UIImage
    private func createImage(from pixelData: [UInt8]) -> UIImage? {
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        
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
    
    // 应用颜色到指定位置
    private func applyColorToPosition() {
        guard !images.isEmpty else { return }
        
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        
        // 计算像素位置
        let x = Int(selectedPosition.x * Double(width))
        let y = Int(selectedPosition.y * Double(height))
        let index = (y * width + x) * 4
        
        // 确保索引有效
        guard index >= 0 && index < (width * height * 4) else { return }
        
        // 获取颜色值
        let uiColor = UIColor(selectedColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 更新像素数据
        if editingImageIndex == 0 && index < pixelData1.count - 3 {
            pixelData1[index] = UInt8(red * 255)
            pixelData1[index + 1] = UInt8(green * 255)
            pixelData1[index + 2] = UInt8(blue * 255)
            pixelData1[index + 3] = UInt8(alpha * 255)
            
            if let newImage = createImage(from: pixelData1) {
                images[0] = newImage
            }
        } else if editingImageIndex == 1 && index < pixelData2.count - 3 {
            pixelData2[index] = UInt8(red * 255)
            pixelData2[index + 1] = UInt8(green * 255)
            pixelData2[index + 2] = UInt8(blue * 255)
            pixelData2[index + 3] = UInt8(alpha * 255)
            
            if let newImage = createImage(from: pixelData2) {
                if images.count > 1 {
                    images[1] = newImage
                } else {
                    images.append(newImage)
                }
            }
        }
    }
    
    // 切换播放状态
    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // 启动定时器
    private func startTimer() {
        let interval = 1.0 / frameRate
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            currentImageIndex = (currentImageIndex + 1) % images.count
        }
    }
    
    // 重启定时器（帧率变化时）
    private func restartTimer() {
        timer?.invalidate()
        if isPlaying {
            startTimer()
        }
    }
    
    // 重置状态
    private func reset() {
        timer?.invalidate()
        isPlaying = false
        currentImageIndex = 0
    }
}
