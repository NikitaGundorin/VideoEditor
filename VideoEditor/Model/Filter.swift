//
//  Filter.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

protocol Filter {
    var name: String { get }
    func apply(forImage image: UIImage?) -> UIImage?
    func apply(forVideo gpuMovie: GPUImageMovie, withVideoView videoView: GPUImageView)
}
