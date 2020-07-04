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
    private var movieURL: URL?
    private var movieAsset: AVURLAsset?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?
    private var gpuMovie: GPUImageMovie?
    private var filters = FiltersFabric.getFilters()
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
            print("Error while getting frame")
        }
        var previewImages = [UIImage?]()
        filters.forEach {
            previewImages.append($0.apply(forImage: previewImage))
        }
        self.previewImages = previewImages
        collectionView.reloadData()
    }
    
    @IBAction func addVideoTapped(_ sender: Any) {
        present(imagePickerController, animated: true, completion: nil)
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
            player?.pause()
            playerLayer?.removeFromSuperlayer()
            movieURL = url
            movieAsset = AVURLAsset(url: url)
            playerItem = AVPlayerItem(asset: movieAsset!)
            player = AVPlayer(playerItem: playerItem)
            gpuMovie = GPUImageMovie(playerItem: playerItem)
            gpuMovie?.removeAllTargets()
            gpuMovie?.addTarget(playerView)
            gpuMovie?.startProcessing()
            player?.play()
            noVideoLabel.alpha = 0
            playerView.backgroundColor = .clear
            setupLayout(hideElements: false)
            setPreviewImage()
        }
        imagePickerController.dismiss(animated: true, completion: nil)
    }
}

