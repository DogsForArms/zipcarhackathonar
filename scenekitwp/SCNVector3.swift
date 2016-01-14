//
//  SCNVector3.swift
//  scenekitwp
//
//  Created by Ethan Sherr on 1/14/16.
//  Copyright © 2016 Ethan Sherr. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3
{
    func scale( c: Float) -> SCNVector3
    {
        return SCNVector3(x: self.x * c, y: self.y * c, z: self.z * c)
    }
    
    func length() -> Float
    {
        return sqrtf( x*x + y*y + z*z )
    }
    
    func normalize() -> SCNVector3
    {
        return self.scale(1/self.length())
    }
    
    
    func dotProduct(b: SCNVector3) -> Float
    {
        return x*b.x + y*b.y + z*b.z
    }

    
    
}

func +(a: SCNVector3, b: SCNVector3) -> SCNVector3
{
    return SCNVector3(a.x+b.x, a.y+b.y, a.z+b.z)
}
func -(a: SCNVector3, b: SCNVector3) -> SCNVector3
{
    return a + b.scale(-1)
}
