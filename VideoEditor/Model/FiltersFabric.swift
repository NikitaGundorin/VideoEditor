//
//  FiltersFabric.swift
//  VideoEditor
//
//  Created by Nikita Gundorin on 04.07.2020.
//  Copyright © 2020 Nikita Gundorin. All rights reserved.
//

import GPUImage

class FiltersFabric {
    static func getFilters() -> [Filter] {
        let blackAndWhiteFilter = BaseFilter(name: "B&W", gpuFilter: GPUImageGrayscaleFilter())
        
        let rgb = GPUImageRGBFilter()
        rgb.blue = 1.5
        let contrast = GPUImageContrastFilter()
        contrast.contrast = 1
        let saturation = GPUImageSaturationFilter()
        saturation.saturation = 0.7
        let look = GroupFilter(name: "LOOK", gpuFilters: [rgb, contrast, saturation])
        
        let scetch = BaseFilter(name: "SKETCH", gpuFilter: GPUImageSketchFilter())
        
        let cGAColorspaceFilter = GPUImageCGAColorspaceFilter()
        
        let vignette = GPUImageVignetteFilter()
        
        let cga = GroupFilter(name: "CGA", gpuFilters: [
            cGAColorspaceFilter,
            vignette
        ])
        
        let filters: [Filter] = [
            blackAndWhiteFilter,
            look,
            scetch,
            cga
        ]

        return filters
    }
}
