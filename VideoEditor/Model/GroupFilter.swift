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
    private let generateGpuFilters: () -> [GPUImageFilter]
    private let gpuFilters: [GPUImageOutput]
    private var movieOutput: GPUImageMovieWriter!
    private var exportMovie: GPUImageMovie!
    
    init(name: String, generateGpuFilters: @escaping () -> [GPUImageFilter]) {
        self.gpuFilters = generateGpuFilters()
        self.generateGpuFilters = generateGpuFilters
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
        gpuFilters.last?.removeAllTargets()
        gpuFilters.last?.addTarget(videoView as GPUImageInput)
        gpuMovie.addTarget(gpuFilters.first as? GPUImageInput)
        gpuMovie.playAtActualSpeed = true
        gpuMovie.startProcessing()
    }
    
    func prepareExport(movieOutput: GPUImageMovieWriter, exportMovie: GPUImageMovie) {
        self.movieOutput = movieOutput
        self.exportMovie = exportMovie
        
        let filters = generateGpuFilters()
        
        exportMovie.addTarget(filters.first)
        filters.last?.addTarget(movieOutput)
    }
}
