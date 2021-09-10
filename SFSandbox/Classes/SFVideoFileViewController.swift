//
//  SFVideoFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class SFVideoFileViewController: SFViewController {

    private lazy var progressBar: VideoProgressBar = {
        let bar = VideoProgressBar()
        return bar
    }()

    private var flatViewModel: SFVideoFileViewModel? { self.viewModel as? SFVideoFileViewModel }
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?

    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFVideoFileViewModel(file: file)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startLoadingVideo()
        view.backgroundColor = .black
        view.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        handleRxBindings()
    }

    private func startLoadingVideo() {
        guard let url = flatViewModel?.videoUrl else { return }
        self.playerItem = AVPlayerItem(url: url)
        guard let playerItem = self.playerItem else {
            viewModel?.errorRelay.accept("视频item初始化失败")
            return
        }
        self.player = AVPlayer(playerItem: playerItem)
        guard let player = self.player else {
            viewModel?.errorRelay.accept("视频player初始化失败")
            return
        }
        let videoLayer = AVPlayerLayer(player: player)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(videoLayer)
    }

    private func handleRxBindings() {
        playerItem?.rx.observe(AVPlayer.Status.self, "status")
            .compactMap { $0 }
            .distinctUntilChanged()
            .bind { [viewModel, player] status in
                switch status {
                case .failed:
                    viewModel?.errorRelay.accept("视频\(viewModel?.fileName ?? "")播放失败")
                case .readyToPlay:
                    player?.play()
                case .unknown:
                    break
                }
        }.disposed(by: disposeBag)
        playerItem?.rx.observe(AVPlayerStatus.self, "loadedTimeRanges")
            .bind { [playerItem, progressBar] _ in
                guard let timeRange = playerItem?.loadedTimeRanges.first?.timeRangeValue else { return }
                let duration = timeRange.start.seconds + timeRange.duration.seconds
                progressBar.duration = Float(duration)
            }.disposed(by: disposeBag)
        player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: DispatchQueue.main, using: { [weak self] time in
            guard let duration = self?.playerItem?.duration.seconds else { return }
            let currentTime = time.seconds
            let progress = currentTime / duration
            if progress >= 1 { self?.seek(to: 0) }
            self?.progressBar.updateProgress(Float(progress))
            self?.progressBar.currentTime = Float(currentTime)
        })
        progressBar.playSubject.bind { [player] play in
            play ? player?.play() : player?.pause()
        }.disposed(by: disposeBag)
        progressBar.progressRelay
            .compactMap { $0 }
            .bind { [weak self] progress in
                self?.seek(to: progress)
            }.disposed(by: disposeBag)
    }

    private func seek(to progress: Float) {
        guard
            let duration = playerItem?.duration.seconds,
            !duration.isNaN,
            let player = self.player
        else { return }
        let time = duration * Double(progress)
        if player.timeControlStatus == .playing { player.pause() }
        let seekTime = CMTime(value: CMTimeValue(time), timescale: 1)
        player.seek(to: seekTime)
    }
}

fileprivate class VideoProgressBar: UIView {

    private lazy var operationButton: UIButton = {
        let button = UIButton()
        button.setImage(SFResources.image(.play), for: .normal)
        button.setImage(SFResources.image(.pause), for: .selected)
        button.isSelected = true
        return button
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.maximumTrackTintColor = .white
        slider.setThumbImage(SFResources.image(.slider), for: .normal)
        return slider
    }()

    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 10)
        return label
    }()

    private lazy var durationTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 10)
        return label
    }()

    private let disposeBag = DisposeBag()
    let playSubject = PublishSubject<Bool>()
    let progressRelay = BehaviorRelay<Float?>(value: nil)
    var duration: Float = 0 {
        didSet { durationTimeLabel.text = duration.formatTime }
    }
    var currentTime: Float = 0 {
        didSet { currentTimeLabel.text = currentTime.formatTime }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(operationButton)
        operationButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(5)
            make.width.equalTo(operationButton.snp.height)
        }
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
            make.left.equalTo(operationButton.snp.right).offset(5)
        }
        addSubview(currentTimeLabel)
        currentTimeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalTo(slider)
        }
        addSubview(durationTimeLabel)
        durationTimeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalTo(slider)
        }
        handleRxBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleRxBindings() {
        operationButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.operationButton.isSelected = !self.operationButton.isSelected
            self.playSubject.onNext(self.operationButton.isSelected)
        }.disposed(by: disposeBag)
        slider.rx.value
            .distinctUntilChanged()
            .compactMap { $0 }
            .bind(to: progressRelay)
            .disposed(by: disposeBag)
        slider.rx.controlEvent(.touchUpInside).bind { [playSubject] in
            playSubject.onNext(true)
        }.disposed(by: disposeBag)
    }

    func updateProgress(_ progress: Float) {
        slider.value = progress
    }
}

extension Float {
    var formatTime: String {
        let time = Int(ceilf(self))
        let hours = Int(time / 3600)
        let minutes = Int((time % 3600) / 60)
        let seconds = Int(((time % 3600) % 60))
        return "\(String(format:"%02d", hours)):\(String(format:"%02d", minutes)):\(String(format:"%02d", seconds))"
    }
}
