//
//  VideoPlayerControlView.swift
//  VideoPlayerDemo
//
//  Created by 李响 on 2018/6/1.
//  Copyright © 2018年 李响. All rights reserved.
//

import UIKit

protocol VideoPlayerControlViewable: NSObjectProtocol {
    
    /// 设置代理对象
    ///
    /// - Parameter delegate: 代理
    func set(delegate: VideoPlayerControlViewDelegate)
    
    /// 设置状态
    ///
    /// - Parameter state: true 播放, false 暂停
    func set(state: Bool)
    
    /// 设置缓冲进度
    ///
    /// - Parameters:
    ///   - progress: 进度
    ///   - animated: 是否动画
    func set(buffer progress: Float, animated: Bool)
    
    /// 设置当前播放时长
    ///
    /// - Parameter time: 时间(秒)
    func set(current time: Float64)
    
    /// 设置总播放时长
    ///
    /// - Parameter time: 时间(秒)
    func set(total time: Float64)
    
    /// 加载状态
    func loadingBegin()
    func loadingEnd()
}

protocol VideoPlayerControlViewDelegate: NSObjectProtocol {
    
    /// 控制播放
    func controlPlay()
    /// 控制暂停
    func controlPause()
    /// 控制跳转指定时间
    func controlSeek(time: Float)
}

class VideoPlayerControlView: UIView {
    
    private weak var delegate: VideoPlayerControlViewDelegate?
    
    lazy var loadingView: UIActivityIndicatorView = {
        $0.activityIndicatorViewStyle = .white
        $0.hidesWhenStopped = true
        return $0
    }( UIActivityIndicatorView() )
    
    lazy var stateButton: UIButton = {
        $0.setImage(#imageLiteral(resourceName: "video_play"), for: .normal)
        $0.setImage(#imageLiteral(resourceName: "video_pause"), for: .selected)
        $0.addTarget(self, action: #selector(stateAction), for: .touchUpInside)
        return $0
    }( UIButton(type: .custom) )
    
    lazy var bottomView: UIView = {
        $0.backgroundColor = .clear
        return $0
    }( UIView() )
    
    lazy var progressView: UIProgressView = {
        $0.progressViewStyle = .default
        $0.progressTintColor = .lightGray
        $0.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        return $0
    }( UIProgressView() )
    
    lazy var sliderView: VideoPlayerSlider = {
        $0.setThumbImage(#imageLiteral(resourceName: "video_slider"), for: .normal)
        $0.minimumTrackTintColor = .cyan
        $0.maximumTrackTintColor = .clear
        $0.addTarget(self, action: #selector(sliderTouchBegin(_:)), for: .touchDown)
        $0.addTarget(self, action: #selector(sliderTouchEnd(_:)), for: [.touchUpInside, .touchUpOutside])
        $0.addTarget(self, action: #selector(sliderTouchCancel(_:)), for: .touchCancel)
        $0.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return $0
    }( VideoPlayerSlider() )
    
    lazy var currentLabel: UILabel = {
        $0.font = .systemFont(ofSize: 10.0)
        $0.textAlignment = .center
        $0.textColor = .white
        $0.text = "00:00"
        return $0
    }( UILabel() )
    
    lazy var totalLabel: UILabel = {
        $0.font = .systemFont(ofSize: 10.0)
        $0.textAlignment = .center
        $0.textColor = .white
        $0.text = "00:00"
        return $0
    }( UILabel() )
    
    private var isShow: Bool = true { didSet { if isShow { show() } else { hide() } } }
    private var isDraging: Bool = false
    private var autoHideTask: VideoPlayerUtils.DelayTask?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        setupLayout()
        
        autoHide()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
        setupLayout()
        
        autoHide()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupLayout()
    }
    
    private func setup() {
        
        backgroundColor = .clear
        
        addSubview(loadingView)
        addSubview(stateButton)
        addSubview(bottomView)
        bottomView.addSubview(progressView)
        bottomView.addSubview(sliderView)
        bottomView.addSubview(currentLabel)
        bottomView.addSubview(totalLabel)
        
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(_:)))
        single.numberOfTapsRequired = 1
        addGestureRecognizer(single)
        
        let double = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(_:)))
        double.numberOfTapsRequired = 2
        addGestureRecognizer(double)
        
        single.require(toFail: double)
    }
    
    private func setupLayout() {
        
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        loadingView.center = center
        stateButton.center = center
        stateButton.bounds = CGRect(x: 0, y: 0, width: 66, height: 66)
        
        bottomView.frame = CGRect(x: 0,
                                  y: bounds.height - 30,
                                  width: bounds.width,
                                  height: 30)
        
        progressView.frame = CGRect(x: 50,
                                    y: bottomView.bounds.height - 15,
                                    width: bottomView.bounds.width - 100,
                                    height: 15)
        sliderView.frame = progressView.frame
        currentLabel.frame = CGRect(x: 0,
                                    y: 0,
                                    width: 50,
                                    height: 30)
        totalLabel.frame = CGRect(x: bottomView.bounds.width - 50,
                                  y: 0,
                                  width: 50,
                                  height: 30)
    }
}

/// 事件处理
extension VideoPlayerControlView {
    
    @objc private func stateAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            delegate?.controlPlay()
        } else {
            delegate?.controlPause()
        }
    }
    
    @objc private func sliderTouchBegin(_ sender: UISlider) {
        isDraging = true
        autoHide(true)
    }
    
    @objc private func sliderTouchEnd(_ sender: UISlider) {
        isDraging = false
        delegate?.controlSeek(time: sender.value)
        autoHide()
    }
    
    @objc private func sliderTouchCancel(_ sender: UISlider) {
        isDraging = false
        autoHide()
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        currentLabel.text = timeToHMS(time: Float64(sender.value))
    }
    
    @objc private func singleTapAction(_ gesture: UITapGestureRecognizer) {
        isShow = !isShow
        autoHide()
    }
    
    @objc private func doubleTapAction(_ gesture: UITapGestureRecognizer) {
        stateAction(stateButton)
    }
}

/// 显示与隐藏控制视图
extension VideoPlayerControlView {
    
    private func show() {
        UIView.beginAnimations("", context: nil)
        UIView.setAnimationDuration(0.2)
        stateButton.alpha = 1.0
        bottomView.alpha = 1.0
        UIView.commitAnimations()
    }
    
    private func hide() {
        UIView.beginAnimations("", context: nil)
        UIView.setAnimationDuration(0.2)
        stateButton.alpha = 0.0
        bottomView.alpha = 0.0
        UIView.commitAnimations()
    }
    
    private func autoHide(_ cancel: Bool = false) {
        VideoPlayerUtils.cancel(task: autoHideTask)
        autoHideTask = nil
        
        if cancel { return }
        
        autoHideTask = VideoPlayerUtils.delay(time: 4.0) { [weak self] in
            guard let this = self else { return }
            
            this.hide()
        }
    }
}

extension VideoPlayerControlView: VideoPlayerControlViewable {
    
    func set(delegate: VideoPlayerControlViewDelegate) {
        self.delegate = delegate
    }
    
    func set(state: Bool) {
        stateButton.isSelected = state
    }
    
    func set(buffer progress: Float, animated: Bool = true) {
        progressView.setProgress(progress, animated: animated)
    }
    
    func set(current time: Float64) {
        guard !isDraging else { return }
        
        sliderView.value = Float(time)
        currentLabel.text = timeToHMS(time: time)
    }
    
    func set(total time: Float64) {
        sliderView.maximumValue = Float(time)
        totalLabel.text = timeToHMS(time: time)
    }
    
    func loadingBegin() {
        loadingView.startAnimating()
    }
    
    func loadingEnd() {
        loadingView.stopAnimating()
    }
}

extension VideoPlayerControlView {
    
    private func timeToHMS(time: Float64) -> String {
        
        let format = DateFormatter()
        if time / 3600 >= 1 {
            format.dateFormat = "HH:mm:ss"
        } else {
            format.dateFormat = "mm:ss"
        }
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let string = format.string(from: date)
        return string
    }
}
