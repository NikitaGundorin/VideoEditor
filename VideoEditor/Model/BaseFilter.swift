//
//  BaseFilter.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

class BaseFilter: Filter {
    let name: String
    private let gpuFilter: GPUImageOutput
    
    init(name: String, gpuFilter: GPUImageOutput) {
        self.name = name
        self.gpuFilter = gpuFilter
    }
    
    func apply(forImage image: UIImage?) -> UIImage? {
        return gpuFilter.image(byFilteringImage: image)
    }
    
    func apply(forVideo gpuMovie: GPUImageMovie, withVideoView videoView: GPUImageView) {
        gpuMovie.removeAllTargets()
        gpuFilter.addTarget(videoView as GPUImageInput)
        gpuMovie.addTarget(gpuFilter as? GPUImageInput)
        gpuMovie.playAtActualSpeed = true
        gpuMovie.startProcessing()
    }
}
