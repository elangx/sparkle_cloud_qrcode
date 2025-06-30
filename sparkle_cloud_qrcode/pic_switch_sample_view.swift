//
//  pic_switch_sample_view.swift
//  sparkle_cloud_qrcode
//
//  Created by Ethan on 2025/6/30.
//

import SwiftUI

#Preview {
    PicSwitchSampleView()
}


struct PicSwitchSampleView: View {
    // 在这里修改颜色值
    let colors: [Color] = [
        Color(red: 0.0, green: 48.0/255.0, blue: 0),   // 蓝色
        Color(red: 56.0/255.0, green: 8.0/255.0, blue: 56.0/255.0)    // 橙色
    ]
    
    // 状态管理
    @State private var currentColorIndex = 0
    @State private var isPlaying = false
    @State private var frameRate: Double = 2  // 默认帧率：2 FPS
    // 使用CADisplayLink进行精确计时
    @State private var displayLink: CADisplayLink?
    @State private var lastFrameTime: CFTimeInterval = 0
    // 实际帧率计算
    @State private var actualFrameRate: Double = 0
    @State private var frameInterval: Double = 0
    @State private var droppedFrameCount: Int = 0
    @State private var frameTimes: [CFTimeInterval] = []
    
    var body: some View {
        VStack {
            // 纯色显示区域
            Rectangle()
                .fill(colors[currentColorIndex])
                .frame(width: 300, height: 300)
                .padding()
                .cornerRadius(12)
            
            // 颜色信息显示
            VStack(spacing: 8) {
                Text("当前颜色")
                    .font(.headline)
                Text(colorDescription(colors[currentColorIndex]))
                    .font(.system(.body, design: .monospaced))
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }
            .padding(.vertical)
            
            // 帧率控制
            VStack(alignment: .leading) {
                Text("帧率: \(String(format: "%.1f", frameRate)) FPS")
                    .font(.headline)
                
                Slider(value: $frameRate, in: 1...60, step: 1) {
                    Text("帧率")
                } minimumValueLabel: {
                    Text("1")
                } maximumValueLabel: {
                    Text("60")
                }
                .padding(.vertical)
                .onChange(of: frameRate, { k,v in
                    restartDisplayLink()
                })
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
            
            //丢帧
            // 颜色信息显示
            VStack(spacing: 8) {
                Text("当前颜色")
                    .font(.headline)
                Text("丢帧：\(String(format: "%d", droppedFrameCount))")
                    .font(.system(.body, design: .monospaced))
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding()
        .onAppear {
            lastFrameTime = CACurrentMediaTime()
        }
        .onDisappear {
            stopDisplayLink()
        }
    }
    
    // 获取颜色的描述信息
    private func colorDescription(_ color: Color) -> String {
        // 将SwiftUI Color转换为UIColor以获取RGB值
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 转换为0-255范围
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return "RGB: (\(r), \(g), \(b))\nHEX: #\(String(format: "%02X%02X%02X", r, g, b))"
    }
    
    // 切换播放状态
    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            startDisplayLink()
        } else {
            stopDisplayLink()
        }
    }
        
    // 启动CADisplayLink
    private func startDisplayLink() {
        stopDisplayLink()
            
        lastFrameTime = CACurrentMediaTime()
        frameTimes.removeAll()
        droppedFrameCount = 0
            
        // 使用 Swift 闭包创建 CADisplayLink
        displayLink = CADisplayLink { [self] displayLink in
            self.updateFrame(displaylink: displayLink)
        }
                
        displayLink?.add(to: .current, forMode: .default)
    }
        
    // 重启CADisplayLink
    private func restartDisplayLink() {
        if isPlaying {
            startDisplayLink()
        }
    }
        
    // 停止CADisplayLink
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
        
    // 重置状态
    private func reset() {
        stopDisplayLink()
        isPlaying = false
        currentColorIndex = 0
    }
        
    // 帧更新逻辑
    private func updateFrame(displaylink: CADisplayLink) {
        currentColorIndex = (currentColorIndex + 1) % 2
    }
}

// CADisplayLink 的 Swift 闭包扩展
extension CADisplayLink {
    convenience init(target: @escaping (CADisplayLink) -> Void) {
        self.init(target: ClosureTarget.self, selector: #selector(ClosureTarget.handleDisplayLink(_:)))
        ClosureTarget.target = target
    }
    
    private class ClosureTarget {
        static var target: ((CADisplayLink) -> Void)?
        
        @objc static func handleDisplayLink(_ displayLink: CADisplayLink) {
            target?(displayLink)
        }
    }
}
