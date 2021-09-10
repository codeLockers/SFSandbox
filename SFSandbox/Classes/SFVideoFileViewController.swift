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
            if progress >= 1 {
                self?.seek(to: 0)
                self?.progressBar.statusRelay.accept(.paused)
            }
            self?.progressBar.updateProgress(Float(progress))
            self?.progressBar.currentTime = Float(currentTime)
        })
        progressBar.progressRelay
            .compactMap { $0 }
            .bind { [weak self] progress in
                self?.seek(to: progress)
            }.disposed(by: disposeBag)
        progressBar.statusRelay
            .distinctUntilChanged()
            .bind { [weak self] status in
                guard let player = self?.player else { return }
                switch status {
                case .paused:
                    if player.timeControlStatus == .playing { player.pause() }
                case .playing:
                    if player.timeControlStatus == .paused { player.play() }
                }
            }.disposed(by: disposeBag)
    }

    private func seek(to progress: Float) {
        guard
            let duration = playerItem?.duration.seconds,
            !duration.isNaN,
            let player = self.player
        else { return }
        let time = duration * Double(progress)
        let seekTime = CMTime(value: CMTimeValue(time), timescale: 1)
        player.seek(to: seekTime)
    }
}

fileprivate class VideoProgressBar: UIView {
    enum Status {
        case playing
        case paused
    }

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
    let statusRelay = BehaviorRelay<Status>(value: .playing)
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
        slider.rx.value
            .skip(1)
            .distinctUntilChanged()
            .compactMap { $0 }
            .map { [statusRelay] progress in
                statusRelay.accept(.paused)
                return progress
            }
            .bind(to: progressRelay)
            .disposed(by: disposeBag)
        slider.rx.controlEvent(.touchUpInside)
            .map { Status.playing }
            .bind(to: statusRelay)
            .disposed(by: disposeBag)
        operationButton.rx.tap
            .map { [weak self] in self?.operationButton.isSelected ?? false }
            .map { $0 ? Status.paused : Status.playing }
            .bind(to: statusRelay)
            .disposed(by: disposeBag)
        statusRelay.distinctUntilChanged()
            .map { status in
                switch status {
                case .playing: return false
                case .paused: return true
                }
            }
            .map { !$0 }
            .bind(to: operationButton.rx.isSelected)
            .disposed(by: disposeBag)
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
