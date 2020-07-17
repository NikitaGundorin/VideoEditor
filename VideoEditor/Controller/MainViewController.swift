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
    @IBOutlet private weak var filtersView: FiltersView!
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
    private lazy var playerService: PlayerServiceProtocol = PlayerService(playerView: playerView) { [unowned self] in
        self.handleError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        filtersView.setup(with: playerService)
    }
    
    private func setupLayout(hideElements: Bool = true) {
        let alpha: CGFloat = hideElements ? 0 : 1
        shareButton.alpha = alpha
        filtersView.alpha = alpha
        chooseFilterLabel.alpha = alpha
        addMusicButton.alpha = alpha
    }
    
    private func handleError(title: String = NSLocalizedString("Video processing error",
                                                               comment: "error alert title"),
                             message: String = NSLocalizedString("Please, try again",
                                                                 comment: "error alert message")) {
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
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        playerService.export { [unowned self] (outputURL: URL?) in
            DispatchQueue.main.async {
                if let url = outputURL {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                } else {
                    self.handleError()
                }
                self.activityIndicator.alpha = 0
                self.activityIndicator.stopAnimating()
            }
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            playerService.movieURL = url
            noVideoLabel.alpha = 0
            playerView.backgroundColor = .clear
            playerView.setBackgroundColorRed(0, green: 0, blue: 0, alpha: 0)
            setupLayout(hideElements: false)
            filtersView.update()
        }
        imagePickerController.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        dismiss(animated: true) {
            guard let song = mediaItemCollection.items.first,
                let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
                    let title = NSLocalizedString("This song is not available", comment: "song error alert title")
                    let message = NSLocalizedString("Please, choose another song", comment: "song error alert message")
                    self.handleError(title: title, message: message)
                    return
            }
            self.playerService.audioURL = url
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
}
