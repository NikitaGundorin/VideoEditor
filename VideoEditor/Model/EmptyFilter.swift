//
//  EmptyFilter.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 05.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

class EmptyFilter: Filter {
    let name = ""
    private var movieOutput: GPUImageMovieWriter!
    private var exportMovie: GPUImageMovie!
    
    func apply(forImage image: UIImage?) -> UIImage? { return nil}
    
    func apply(forVideo gpuMovie: GPUImageMovie, withVideoView videoView: GPUImageView) {}
    
    func prepareExport(movieOutput: GPUImageMovieWriter, exportMovie: GPUImageMovie) {
        self.movieOutput = movieOutput
        self.exportMovie = exportMovie
        
        exportMovie.addTarget(movieOutput)
        
    }
}
