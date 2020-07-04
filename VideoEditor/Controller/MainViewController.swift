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
    @IBOutlet weak var noVideoLabel: UILabel!
    @IBOutlet private weak var addVideoButton: UIButton!
    @IBOutlet private weak var addMusicButton: UIButton!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupLayout() {
        shareButton.alpha = 0
    }
    
    @IBAction func addVideoTapped(_ sender: Any) {
        present(imagePickerController, animated: true, completion: nil)
    }
}

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //apply filter
    }
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 //filters count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filterCell", for: indexPath)
        //set image and filter's name
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
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspect
            playerLayer?.frame = playerView.bounds
            playerView?.layer.addSublayer(playerLayer!)
            player?.play()
            noVideoLabel.alpha = 0
            playerView.backgroundColor = .clear
            shareButton.alpha = 1
        }
        imagePickerController.dismiss(animated: true, completion: nil)
    }
}

