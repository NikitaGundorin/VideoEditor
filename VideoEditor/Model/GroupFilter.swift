//
//  GroupFilter.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

class GroupFilter: Filter {
    let name: String
    private var gpuFilters: [GPUImageOutput]
    
    init(name: String, gpuFilters: [GPUImageOutput]) {
        for (i, filter) in gpuFilters.enumerated() {
            if (i == gpuFilters.count - 1) { break }
            filter.addTarget(gpuFilters[i + 1] as? GPUImageInput)
        }

        self.gpuFilters = gpuFilters
        self.name = name
    }
    
    func apply(forImage image: UIImage?) -> UIImage? {
        guard let inputImage = image,
            let picture = GPUImagePicture(image: inputImage)
        else { return image }
        
        picture.addTarget(gpuFilters.first as? GPUImageInput)
        picture.processImage()
        gpuFilters.last?.useNextFrameForImageCapture()
        guard let result = gpuFilters.last?.imageFromCurrentFramebuffer() else { return image }
        return result
    }
    
    func apply(forVideo gpuMovie: GPUImageMovie, withVideoView videoView: GPUImageView) {
        gpuMovie.removeAllTargets()
        for (i, filter) in gpuFilters.enumerated() {
            if (i == gpuFilters.count - 1) { break }
            filter.addTarget(gpuFilters[i + 1] as? GPUImageInput)
        }
        gpuFilters.last?.addTarget(videoView as GPUImageInput)
        gpuMovie.addTarget(gpuFilters.first as? GPUImageInput)
        gpuMovie.playAtActualSpeed = true
        gpuMovie.startProcessing()
    }
}
