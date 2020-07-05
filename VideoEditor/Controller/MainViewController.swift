//
//  ViewController.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import GPUImage
import MediaPlayer

class MainViewController: UIViewController {
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var playerView: GPUImageView!
    @IBOutlet private weak var noVideoLabel: UILabel!
    @IBOutlet private weak var addVideoButton: UIButton!
    @IBOutlet private weak var addMusicButton: UIButton!
    @IBOutlet private weak var chooseFilterLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    private lazy var imagePickerController: UIImagePickerController = {
        let ipc = UIImagePickerController()
        ipc.sourceType = .photoLibrary
        ipc.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
        ipc.delegate = self
        ipc.videoExportPreset = AVAssetExportPresetPassthrough
        return ipc
    }()
    private lazy var mediaPicker: MPMediaPickerController = {
        let mpc = MPMediaPickerController(mediaTypes: .music)
        mpc.showsItemsWithProtectedAssets = false
        mpc.showsCloudItems = false
        mpc.allowsPickingMultipleItems = false
        mpc.delegate = self
        return mpc
    }()
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .whiteLarge)
        ai.alpha = 0
        view.addSubview(ai)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        ai.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        ai.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        ai.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        ai.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7490635702)
        return ai
    }()
    private var movieURL: URL?
    private var movieAsset: AVAsset?
    private var audioAsset: AVAsset?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?
    private var gpuMovie: GPUImageMovie?
    private var filters = FiltersFabric.getFilters()
    private var emptyFilter = EmptyFilter()
    private var previewImage = UIImage(named: "example")
    private lazy var previewImages = [UIImage?](repeating: UIImage(), count: filters.count)
    private var checkedCell: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupLayout(hideElements: Bool = true) {
        let alpha: CGFloat = hideElements ? 0 : 1
        shareButton.alpha = alpha
        collectionView.alpha = alpha
        chooseFilterLabel.alpha = alpha
        addMusicButton.alpha = alpha
    }
    
    private func setPreviewImage() {
        guard let asset = movieAsset else { return }
        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
        
        let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
        do {
            let cgFrame = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            previewImage = UIImage(cgImage: cgFrame)
        } catch {
            handleError()
        }
        var previewImages = [UIImage?]()
        filters.forEach {
            previewImages.append($0.apply(forImage: previewImage))
        }
        self.previewImages = previewImages
        collectionView.reloadData()
    }
    
    private func updatePlayer() {
        guard let asset = movieAsset else { return }
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        gpuMovie = GPUImageMovie(playerItem: playerItem)
        if let indexPath = checkedCell {
            filters[indexPath.item].apply(forVideo: gpuMovie!, withVideoView: playerView)
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
            handleError()
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
                handleError()
                return
            }
        }
        
        self.movieAsset = mixComposition
        updatePlayer()
    }
    
    private func handleError(title: String = "Video processing error", message: String = "Please, try again") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func addVideoTapped(_ sender: Any) {
        present(imagePickerController, animated: true, completion: nil)
    }
    @IBAction private func addMusicTapped(_ sender: Any) {
        present(mediaPicker, animated: true, completion: {})
    }
    private var movieOutput: GPUImageMovieWriter!
    private var exportMovie: GPUImageMovie!
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        shareButton.isEnabled = false
        guard let movieAsset = movieAsset else {
            handleError()
            return
        }
        let completionBlock = { (outputURL: URL?) in
            DispatchQueue.main.async {
                if let url = outputURL {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                } else {
                    self.handleError()
                }
                self.shareButton.isEnabled = true
                self.activityIndicator.alpha = 0
                self.activityIndicator.stopAnimating()
            }
        }
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        if let indexPath = checkedCell {
            filters[indexPath.item].export(asset: movieAsset, completion: completionBlock)
        } else {
            emptyFilter.export(asset: movieAsset, completion: completionBlock)
        }
    }
}

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let gpuMovie = gpuMovie else { return }
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.checked = true
        }
        checkedCell = indexPath
        filters[indexPath.item].apply(forVideo: gpuMovie, withVideoView: playerView)
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.checked = false
        }
    }
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filterCell", for: indexPath)
        if let cell = cell as? FilterCell {
            cell.previewImage = previewImages[indexPath.item]
            cell.name = filters[indexPath.item].name
            cell.checked = checkedCell == indexPath
        }
        return cell
    }
}

extension MainViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            movieURL = url
            movieAsset = AVURLAsset(url: url)
            checkedCell = nil
            updatePlayer()
            noVideoLabel.alpha = 0
            playerView.backgroundColor = .clear
            setupLayout(hideElements: false)
            setPreviewImage()
        }
        imagePickerController.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        dismiss(animated: true) {
            guard let song = mediaItemCollection.items.first,
                let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
                    self.handleError(title: "This song is not available", message: "Please, choose another song")
                    return
            }
            self.audioAsset = AVAsset(url: url)
            self.addAudio()
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
}
