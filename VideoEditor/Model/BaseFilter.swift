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
    private let generateGpuFilter: () -> GPUImageFilter
    private let gpuFilter: GPUImageFilter
    private var movieOutput: GPUImageMovieWriter!
    private var exportMovie: GPUImageMovie!
    
    init(name: String, generateGpuFilter: @escaping () -> GPUImageFilter) {
        self.name = name
        self.generateGpuFilter = generateGpuFilter
        self.gpuFilter = generateGpuFilter()
    }
    
    func apply(forImage image: UIImage?) -> UIImage? {
        return gpuFilter.image(byFilteringImage: image)
    }
    
    func apply(forVideo gpuMovie: GPUImageMovie, withVideoView videoView: GPUImageView) {
        gpuMovie.removeAllTargets()
        gpuFilter.removeAllTargets()
        gpuFilter.addTarget(videoView as GPUImageInput)
        gpuMovie.addTarget(gpuFilter)
        gpuMovie.playAtActualSpeed = true
        gpuMovie.startProcessing()
    }
    
    func prepareExport(movieOutput: GPUImageMovieWriter, exportMovie: GPUImageMovie) {
        self.movieOutput = movieOutput
        self.exportMovie = exportMovie
        
        let filter = generateGpuFilter()
        
        exportMovie.addTarget(filter)
        filter.addTarget(movieOutput)
    }
}
