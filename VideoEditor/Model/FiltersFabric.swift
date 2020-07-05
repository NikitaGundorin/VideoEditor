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
        let blackAndWhiteFilter = BaseFilter(name: "B&W") {
            GPUImageGrayscaleFilter()
        }
        
        let look = GroupFilter(name: "LOOK") {
            let rgb = GPUImageRGBFilter()
            rgb.blue = 1.5
            let contrast = GPUImageContrastFilter()
            contrast.contrast = 1
            let saturation = GPUImageSaturationFilter()
            saturation.saturation = 0.7
            
            rgb.addTarget(contrast)
            contrast.addTarget(saturation)
            
            return [rgb, contrast, saturation]
        }
        
        let scetch = BaseFilter(name: "SKETCH") {
            GPUImageSketchFilter()
        }
        
        let cga = GroupFilter(name: "CGA") {
            let cGAColorspaceFilter = GPUImageCGAColorspaceFilter()
            let vignette = GPUImageVignetteFilter()
            cGAColorspaceFilter.addTarget(vignette)
            
            return [cGAColorspaceFilter, vignette]
        }
        
        let filters: [Filter] = [
            blackAndWhiteFilter,
            look,
            scetch,
            cga
        ]

        return filters
    }
}
