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
    @State private var isOpenFrameSync = false
    @State private var displayLink: CADisplayLink?
    @State private var lastFrameTime: CFTimeInterval = 0
    // 固定帧率
    @State private var timer: Timer? = nil
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
                    restartDisplay()
                })
                .disabled(displayLink != nil)
                
                Toggle("开启帧同步", isOn: $isOpenFrameSync)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: isOpenFrameSync, {k, v in
                    restartDisplay()
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
            startDisplay()
        } else {
            stopDisplay()
        }
    }
    
    //开始刷新
    private func startDisplay() {
        if isOpenFrameSync {
            startDisplayLink()
        } else {
            startFPSDisplay()
        }
    }
    
    // 关闭刷新
    private func stopDisplay() {
        stopDisplayLink()
        stopTimer()
    }
    
    // 重置状态
    private func reset() {
        stopDisplay()
        isPlaying = false
        currentColorIndex = 0
        frameRate = 2
    }
    
    // 重启刷新
    private func restartDisplay() {
        if isPlaying {
            if isOpenFrameSync {
                stopTimer()
                startDisplayLink()
            } else {
                stopDisplayLink()
                startFPSDisplay()
            }
        }
    }
        
    
    //开启固定帧刷新
    private func startFPSDisplay() {
        let interval = 1.0 / frameRate
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            updateFrame()
        }
    }
    
    // 重启定时器（帧率变化时）
    private func restartTimer() {
        timer?.invalidate()
        if isPlaying {
            startFPSDisplay()
        }
    }
    
    //停止定制器
    private func stopTimer() {
        timer?.invalidate()
    }
    
    // 启动CADisplayLink
    private func startDisplayLink() {
        stopDisplayLink()
            
        lastFrameTime = CACurrentMediaTime()
        frameTimes.removeAll()
        droppedFrameCount = 0
            
        // 使用 Swift 闭包创建 CADisplayLink
        displayLink = CADisplayLink { [self] displayLink in
            self.updateFrame()
        }
                
        displayLink?.add(to: .current, forMode: .default)
    }
        
    // 停止CADisplayLink
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

        
    // 帧更新逻辑
    private func updateFrame() {
        currentColorIndex = (currentColorIndex + 1) % colors.count
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
