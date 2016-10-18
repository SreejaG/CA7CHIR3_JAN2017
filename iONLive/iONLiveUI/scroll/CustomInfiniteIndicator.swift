//
//  CustomInfiniteIndicator.swift
//  InfiniteScrollViewDemoSwift
//
//  Created by pronebird on 5/3/15.
//  Copyright (c) 2015 pronebird. All rights reserved.
//

import UIKit

private let rotationAnimationKey = "rotation"

class CustomInfiniteIndicator: UIView {
    
    var thickness: CGFloat = 4
    var outerColor = UIColor.grayColor().colorWithAlphaComponent(0.2)
    
    lazy var innerColor: UIColor = {
        return self.tintColor
    }()

    private var animating = false
    private let innerCircle = CAShapeLayer()
    private let outerCircle = CAShapeLayer()
    private var startTime = CFTimeInterval(0)
    private var stopTime = CFTimeInterval(0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        unregisterFromAppStateNotifications()
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        setupBezierPaths()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if let _ = window {
            restartAnimationIfNeeded()
        }
    }
    
    // MARK: - Private
    
    private func commonInit() {
        registerForAppStateNotifications()
        
        hidden = true
        backgroundColor = UIColor.clearColor()
        
        outerCircle.strokeColor = outerColor.CGColor
        outerCircle.fillColor = UIColor.clearColor().CGColor
        outerCircle.lineWidth = thickness
        
        innerCircle.strokeColor = innerColor.CGColor
        innerCircle.fillColor = UIColor.clearColor().CGColor
        innerCircle.lineWidth = thickness
        
        layer.addSublayer(outerCircle)
        layer.addSublayer(innerCircle)
    }
    
    private func addAnimation() {
        let anim = animation()
        anim.timeOffset = stopTime - startTime
        
        layer.addAnimation(anim, forKey: rotationAnimationKey)
        
        startTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
    }
    
    private func removeAnimation() {
        layer.removeAnimationForKey(rotationAnimationKey)
        
        stopTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
    }
    
    func restartAnimationIfNeeded() {
        let anim = layer.animationForKey(rotationAnimationKey)
        
        if animating && anim == nil {
            removeAnimation()
            addAnimation()
        }
    }
    
    private func registerForAppStateNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CustomInfiniteIndicator.restartAnimationIfNeeded), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    private func unregisterFromAppStateNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func animation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = NSNumber(double: M_PI * 2)
        animation.duration = 0.7
        animation.repeatCount = Float.infinity
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        return animation
    }
    
    private func setupBezierPaths() {
        let center = CGPointMake(bounds.size.width * 0.5, bounds.size.height * 0.5)
        let radius = bounds.size.width * 0.5 - thickness
        let ringPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2), clockwise: true)
        let quarterRingPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(-M_PI_4), endAngle: CGFloat(M_PI_2 - M_PI_4), clockwise: true)
        
        outerCircle.path = ringPath.CGPath
        innerCircle.path = quarterRingPath.CGPath
    }
    
    // MARK: - Public
    
    func isAnimating() -> Bool {
        return animating
    }
    
    func startAnimating() {
        if animating {
            return
        }
        animating = true
        hidden = false
        addAnimation()
    }
    
    func stopAnimationg() {
        if !animating {
            return
        }
        animating = false
        hidden = true
        removeAnimation()
    }

}
