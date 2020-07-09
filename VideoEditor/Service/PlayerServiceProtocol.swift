//
//  PlayerServiceProtocol.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 06.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

protocol PlayerServiceProtocol {
    var filter: Filter? { get set }
    var movieURL: URL? { get set }
    var audioURL: URL? { get set }
    
    func apply(filter: Filter)
    func getPreviewImages(filters: [Filter]) -> [UIImage?]
    func export(completion: @escaping (URL?) -> ())
}
