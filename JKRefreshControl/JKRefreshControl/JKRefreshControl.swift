// MIT License
//
// Copyright (c) 2016 EnjoySR (https://github.com/EnjoySR/JKRefreshControl)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit


/// 刷新控件的状态
///
/// - normal:     默认
/// - pulling:    松开就可刷新
/// - refreshing: 刷新中
enum JKRefreshState: Int {
    case normal = 0, pulling, refreshing
}

private let RefreshControlWH: CGFloat = 45
/// 处于刷新中状态时，顶部多余的刷新高度
private let RefreshingStayHeight: CGFloat = 70
/// 控件从刷新状态重置为默认状态的时间
private let RefreshControlHideDuration: TimeInterval = 0.5
/// 主题颜色
private let ThemeColor = UIColor(red: 59/255, green: 84/255, blue: 106/255, alpha: 1)
/// 线宽
private let LineWidth: CGFloat = 5
/// 顶部矩形高度
private let LineHeight: CGFloat = 16
/// 内圆半径
private let InnerRadius: CGFloat = 8
/// 绘制的中心点
private let DrawCenter = CGPoint(x: RefreshControlWH * 0.5, y: RefreshControlWH * 0.5)

class JKRefreshControl: UIControl {
    
    
    // MARK: - 一些属性
    
    // 是否正在执行刷新中的动画，防止用户来回拖动 scrollView 造成重复添加动画
    fileprivate var isRefreshingAnim: Bool = false
    // 是否已经开始执行刷新，防止用户在未刷新完成的情况下重复触发
    fileprivate var isBeginRefreshing: Bool = false
    
    
    /// 刷新状态
    fileprivate var refreshState: JKRefreshState = .normal {
        didSet {
            print(refreshState)
            
            switch refreshState {
            case .refreshing:
                
                // 调整顶部距离
                var inset = self.superView.contentInset
                inset.top = inset.top + RefreshingStayHeight
                DispatchQueue.main.async {
                    UIView.animate(withDuration: RefreshControlHideDuration, animations: {
                        self.superView.contentInset = inset
                        self.superView.setContentOffset(CGPoint(x: 0, y: -inset.top), animated: false)
                        }, completion: { (_) in
                            self.sendActions(for: .valueChanged)
                    })
                }
            case .normal:
                // 移除两个layer的路径
                bottomLayer.path = nil
                topLayer.path = nil
                // 为默认状态时，重置属性
                bottomLayer.removeAllAnimations()
                topLayer.strokeEnd = 1
                bottomLayer.lineWidth = LineWidth
                isRefreshingAnim = false
                // 重置是否开始刷新的状态
                isBeginRefreshing = false
                
            default:
                break
            }
        }
    }
    /// 父控件
    private var superView: UIScrollView!
    /// 默认的centerY
    lazy var defaultCenterY: CGFloat = {
        return -self.frame.height * 0.5 - 12.5
    }()
    /// 拖动距离计算出来的填充比
    var contentOffsetScale: CGFloat = 0 {
        didSet {
            // 当前比例值大于 1 的时候，就设置为 1
            if contentOffsetScale > 1 {
                contentOffsetScale = 1
            }
            // 当比例值小于 0 的时候，就设置为 0
            if contentOffsetScale <= 0 {
                contentOffsetScale = 0
            }
        }
    }
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        
        frame.size = CGSize(width: RefreshControlWH, height: RefreshControlWH)
        backgroundColor = UIColor.clear
        
        // 添加三个layer
        layer.addSublayer(bgGrayLayer)
        layer.addSublayer(bottomLayer)
        layer.addSublayer(topLayer)
        
    }
    
    /// 设置控件的初始位置
    ///
    /// - parameter superViewFrame: 父控件的位置
    private func setLocation(superViewFrame: CGRect) {
        // 后面的减 12.5 是为了确定其 y 值与 官方 app 的 y 值一样
        self.center = CGPoint(x: superViewFrame.width * 0.5, y: -self.frame.height * 0.5 - 12.5)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let superView = newSuperview as? UIScrollView {
            self.superView = superView
            // 监听superView的frame变化
            superView.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.new, context: nil)
            // 监听superView的滚动
            superView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
        }
    }
    
    // MARK: - 外部接口
    
    
    /// 开始刷新
    func beginRefreshing() {
        
        if isBeginRefreshing {
            return
        }
        
        isBeginRefreshing = true
        let contentInsetY = superView.contentInset
        UIView.animate(withDuration: 0.25, animations: {
            self.superView.setContentOffset(CGPoint(x: 0, y: -contentInsetY.top - RefreshingStayHeight), animated: false)
        }) { (_) in
            self.refreshState = .refreshing
            self.drawInLayer()
        }
    }
    
    /// 结束刷新
    func endRefreshing() {
        
        // 执行转圈的layer的线宽的动画
        let animation = CABasicAnimation(keyPath: "lineWidth")
        animation.toValue = 0
        animation.duration = 0.5
        // 设置最终线宽为 0,保证动画执行完毕之后不再显示
        bottomLayer.lineWidth = 0
        bottomLayer.add(animation, forKey: nil)
        
        // 重置 contentInset
        var inset = self.superView.contentInset
        inset.top = inset.top - RefreshingStayHeight
        UIView.animate(withDuration: RefreshControlHideDuration, animations: {
            self.superView.contentInset = inset
            self.superView.setContentOffset(CGPoint(x: 0, y: -inset.top), animated: false)
            }, completion: { (_) in
                self.refreshState = .normal
        })
    }
    
    // MARK: - KVO 监听 scrollView 滚动
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            self.dealContentOffsetYChanged()
        }else if keyPath == "frame" {
            let value = (change![NSKeyValueChangeKey.newKey] as! NSValue).cgRectValue
            self.setLocation(superViewFrame: value)
        }
    }
    
    
    /// 处理contentOffsetY改变
    // 1. 改变控件的Y值
    // 2. 改变刷新控件的状态
    private func dealContentOffsetYChanged() {
        // 取出偏移的y值
        let contentOffsetY = superView.contentOffset.y;
        
        print("contentOffsetY = \(contentOffsetY)")
        
        // 1. 设置 控件的 y 值
        // 通过偏移量与顶部间距计算数当前控件的中心点
        let result = (contentOffsetY + superView.contentInset.top) / 2
        // 判断计算出来的值是否比默认的Y值还要小，如果小，就设置该Y值
        if result < defaultCenterY {
            self.center = CGPoint(x: self.center.x, y: result)
        }else{
            // 否则继续设置为默认Y值
            self.center = CGPoint(x: self.center.x, y: defaultCenterY)
        }
        
        // 2. 更改控件的状态
        // 如果正在被拖动
        if superView.isDragging {
            // 如果空白中心点小于控件的默认中心y值，并且当前状态是默认状态，就进行 `松手就刷新的状态`
            if result < defaultCenterY &&  refreshState == .normal {
                refreshState = .pulling
            }else if result >= defaultCenterY &&  refreshState == .pulling {
                // 如果空白中心点大于等于控件的默认中心y值，并且当前状态是默认状态，就进入 `默认状态`
                refreshState = .normal
            }
        }else {
            // 用户已松手，判断当前状态如果是 `pulling` 状态就进行刷新状态
            if refreshState == .pulling {
                refreshState = .refreshing
            }
        }
        
        // 3. 计算 scale
        // 通过拖动的距离计算.公式为：比例 = 拖动的距离 / 控件的高度
        let scale = -(superView.contentOffset.y + superView.contentInset.top) / RefreshingStayHeight
        self.contentOffsetScale = scale
        self.drawInLayer()
    }
    
    deinit {
        superView.removeObserver(self, forKeyPath: "contentOffset")
        superView.removeObserver(self, forKeyPath: "frame")
    }
    
    // MARK: - 懒加载layer
    
    // 背景灰色的layer，显示 `J`
    fileprivate lazy var bgGrayLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let bgColor = UIColor(red: 222/255, green: 226/255, blue: 229/255, alpha: 1)
        layer.fillColor = bgColor.cgColor
        layer.strokeColor = bgColor.cgColor
        return layer
    }()
    
    
    // 底部layer,显示 `J` 的下半部分
    fileprivate lazy var bottomLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = ThemeColor.cgColor
        // 设置线宽
        layer.lineWidth = LineWidth
        // 设置frame，用于转圈
        layer.frame = self.bounds
        return layer
    }()
    
    // 顶部layer，显示 `J` 的上半部分
    fileprivate lazy var topLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = ThemeColor.cgColor
        layer.lineWidth = LineWidth
        return layer
    }()
}

// MARK: - 更新界面
extension JKRefreshControl {
    
    /// 绘制 layer 中的内容
    fileprivate func drawInLayer() {
        
        // 开始角度
        let startAngle = CGFloat(M_PI) / 2
        // 结束角度
        let endAngle: CGFloat = 0
        
        if refreshState == .refreshing {
            // 判断如果正在刷新的话，就不需要再次执行动画
            if isRefreshingAnim {
                return
            }
            // 调整执行动画属性为true
            isRefreshingAnim = true
            // 清空背景灰色的layer
            bgGrayLayer.path = nil
            
            // 底部半圆到整圆
            let bottomPath = UIBezierPath(arcCenter: DrawCenter, radius: InnerRadius + LineWidth * 0.5, startAngle: 0, endAngle: CGFloat(M_PI) * 2 - 0.1, clockwise: true)
            bottomLayer.path = bottomPath.cgPath
            
            // 执行动画
            let bottomAnim = CABasicAnimation(keyPath: "strokeEnd")
            bottomAnim.fromValue = NSNumber(value: 0.25)
            bottomAnim.toValue = NSNumber(value: 1.0)
            bottomAnim.duration = 0.15
            bottomLayer.add(bottomAnim, forKey: nil)
            
            // 顶部Path
            let topPath = UIBezierPath()
            topPath.lineCapStyle = .square
            topPath.move(to: CGPoint(x: DrawCenter.x + InnerRadius + LineWidth * 0.5, y: DrawCenter.y))
            topPath.addLine(to: CGPoint(x: DrawCenter.x + InnerRadius + LineWidth * 0.5, y: DrawCenter.y - (contentOffsetScale - 0.5) * 2 * LineHeight))
            topLayer.path = topPath.cgPath
            
            // 竖线变短动画
            let topAnim = CABasicAnimation(keyPath: "strokeEnd")
            topAnim.fromValue = NSNumber(value: 1)
            topAnim.toValue = NSNumber(value: 0)
            topAnim.duration = 0.15
            topLayer.strokeEnd = 0;
            topLayer.add(topAnim, forKey: nil)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15, execute: {
                // 0.15 秒之后进行转圈
                self.runaroundAnim()
            })
            return
        }
        
        // 绘制默认状态与松手就刷新状态的代码
        // 绘制灰色背景 layer 内容
        // 画 1/4 圆
        let path = UIBezierPath(arcCenter: DrawCenter, radius: InnerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        // 添加左边竖线
        path.addLine(to: CGPoint(x: path.currentPoint.x, y: DrawCenter.y - LineHeight))
        // 添加顶部横线
        path.addLine(to: CGPoint(x: path.currentPoint.x + LineWidth, y: path.currentPoint.y))
        // 添加右边竖线
        path.addLine(to: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y + LineHeight))
        // 添加外圆
        path.addArc(withCenter: DrawCenter, radius: InnerRadius + LineWidth, startAngle: endAngle, endAngle: startAngle - 0.05, clockwise: true)
        path.close()
        // 设置路径
        bgGrayLayer.path = path.cgPath
        
        // 如果小于0.016.在画度半圆的时候会反方向画
        if contentOffsetScale < 0.016 {
            bgGrayLayer.path = nil
            bottomLayer.path = nil
            topLayer.path = nil
            return
        }

        /// 提供内部方法，专门用于获取绘制底部的圆的 path
        func pathForBottomCircle(contentOffsetScale: CGFloat) -> UIBezierPath {
            // 记录传入的比例
            var scale = contentOffsetScale
            // 如果比例大于 0.5，那么设置为 0.5
            if scale > 0.5 {
                scale = 0.5
            }
            // 计算出开始角度与结束角度
            let targetStartAngle = startAngle
            let targetEndAngle = startAngle - startAngle * scale * 2
            // 初始化 path 并返回
            let drawPath = UIBezierPath(arcCenter: DrawCenter, radius: InnerRadius + LineWidth * 0.5, startAngle: targetStartAngle, endAngle: targetEndAngle, clockwise: false)
            
            return drawPath
        }
        
        bottomLayer.path = pathForBottomCircle(contentOffsetScale: contentOffsetScale).cgPath
        // 判断如果拖动比例小于0.5，只画半圆
        if contentOffsetScale <= 0.5 {
            topLayer.path = nil
        }else {
            // 画顶部竖线
            let topPath = UIBezierPath()
            topPath.lineCapStyle = .square
            topPath.move(to: CGPoint(x: DrawCenter.x + InnerRadius + LineWidth * 0.5, y: DrawCenter.y))
            topPath.addLine(to: CGPoint(x: DrawCenter.x + InnerRadius + LineWidth * 0.5, y: DrawCenter.y - (contentOffsetScale - 0.5) * 2 * LineHeight))
            topLayer.path = topPath.cgPath
        }
    }
    
    
    /// 转圈动画
    private func runaroundAnim() {
        // 执行转圈动画
        let bottomPath = UIBezierPath(arcCenter: DrawCenter, radius: InnerRadius + LineWidth * 0.5, startAngle: 0, endAngle: CGFloat(M_PI) * 2 - 0.1, clockwise: true)
        self.bottomLayer.path = bottomPath.cgPath
        
        // 围绕 z 轴转圈
        let bottomAnim = CABasicAnimation(keyPath: "transform.rotation.z")
        bottomAnim.fromValue = NSNumber(value: 0)
        bottomAnim.toValue = NSNumber(value: 2 * M_PI)
        bottomAnim.duration = 0.5
        bottomAnim.repeatCount = MAXFLOAT
        self.bottomLayer.add(bottomAnim, forKey: "runaroundAnim")
    }
}
