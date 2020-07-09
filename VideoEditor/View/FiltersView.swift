//
//  FiltersView.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 07.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import UIKit

class FiltersView: UIView {
    @IBOutlet private weak var collectionView: UICollectionView!
    var playerService: PlayerServiceProtocol?
    private var filters = FiltersFabric.getFilters()
    private var checkedCell: IndexPath?
    private lazy var previewImages = [UIImage?](repeating: UIImage(), count: filters.count)
    
    func setup(with playerService: PlayerServiceProtocol) {
        self.playerService = playerService
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func update() {
        guard let playerService = playerService else { return }
        previewImages = playerService.getPreviewImages(filters: filters)
        checkedCell = nil
        collectionView.reloadData()
    }
}

extension FiltersView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.checked = true
        }
        checkedCell = indexPath
        playerService?.apply(filter: filters[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.checked = false
        }
    }
}

extension FiltersView: UICollectionViewDataSource {
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

extension FiltersView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: 74, height: 111)
    }
}
