//
//  FilterCell.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {
    var previewImage: UIImage? {
        didSet {
            previewImageView.image = previewImage
        }
    }
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    var checked: Bool = false {
        didSet {
            checkmark.alpha = checked ? 1 : 0
        }
    }
    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var checkmark: UIImageView!
}
