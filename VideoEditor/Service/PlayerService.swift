//
//  PlayerService.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 06.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import AVFoundation
import GPUImage

class PlayerService: PlayerServiceProtocol {
    var filter: Filter?
    private var playerView: GPUImageView
    var movieURL: URL? {
        didSet {
            if let url = movieURL {
                movieAsset = AVURLAsset(url: url)
                filter = nil
                updatePlayer()
            }
        }
    }
    var audioURL: URL? {
        didSet {
            if let url = audioURL {
                audioAsset = AVAsset(url: url)
                addAudio()
            }
        }
    }
    private var movieAsset: AVAsset?
    private var audioAsset: AVAsset?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?
    private var gpuMovie: GPUImageMovie?
    private var errorHandler: () -> ()
    private var emptyFilter = EmptyFilter()
    
    init(playerView: GPUImageView, errorHandler: @escaping () -> ()) {
        self.errorHandler = errorHandler
        self.playerView = playerView
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
                                                self?.player?.seek(to: CMTime.zero)
                                                self?.player?.play()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func apply(filter: Filter) {
        guard let gpuMovie = gpuMovie else { return }
        self.filter = filter
        filter.apply(forVideo: gpuMovie, withVideoView: playerView)
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    func getPreviewImages(filters: [Filter]) -> [UIImage?] {
        guard let asset = movieAsset else { return [] }
        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
        var previewImage = UIImage()
        let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
        do {
            let cgFrame = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            previewImage = UIImage(cgImage: cgFrame)
        } catch {
            errorHandler()
        }
        var previewImages = [UIImage?]()
        filters.forEach {
            previewImages.append($0.apply(forImage: previewImage))
        }
        return previewImages
    }
    
    func export(completion: @escaping (URL?) -> ()) {
        guard let movieAsset = movieAsset else {
            errorHandler()
            return
        }
        if let filter = filter {
            filter.export(asset: movieAsset, completion: completion)
        } else {
            emptyFilter.export(asset: movieAsset, completion: completion)
        }
    }
    
    private func updatePlayer() {
        guard let asset = movieAsset else { return }
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        gpuMovie = GPUImageMovie(playerItem: playerItem)
        if let filter = filter {
            filter.apply(forVideo: gpuMovie!, withVideoView: playerView)
        } else {
            gpuMovie?.addTarget(playerView)
            gpuMovie?.startProcessing()
        }
        player?.play()
    }
    
    private func addAudio() {
        guard let movieAsset = movieAsset else { return }
        let mixComposition = AVMutableComposition()
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            else { return }
        
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: movieAsset.duration),
                                           of: movieAsset.tracks(withMediaType: AVMediaType.video)[0],
                                           at: .zero)
        } catch {
            errorHandler()
            return
        }
        
        if let loadedAudioAsset = audioAsset {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                duration: movieAsset.duration),
                                                of: loadedAudioAsset.tracks(withMediaType: AVMediaType.audio)[0] ,
                                                at: .zero)
            } catch {
                errorHandler()
                return
            }
        }
        
        self.movieAsset = mixComposition
        updatePlayer()
    }
}
