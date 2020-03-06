//
//  CanvasView.swift
//  freehandDrawingOnMap
//
//  Created by Fadilah Hasan on 06/03/20.
//  Copyright © 2020 Fadilah Hasan. All rights reserved.
//

import UIKit

protocol NotifyTouchEvents: class {
    
    func touchBegan(touch:UITouch)
    func touchEnded(touch:UITouch)
    func touchMoved(touch:UITouch)
}

class CanvasView: UIImageView {
    
    weak var delegate:NotifyTouchEvents?
    var lastPoint = CGPoint.zero
    let brushWidth:CGFloat = 3.0
    let opacity :CGFloat = 1.0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.delegate?.touchBegan(touch: touch)
            lastPoint = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first  {
            self.delegate?.touchMoved(touch: touch)
            let currentPoint = touch.location(in: self)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first  {
            self.delegate?.touchEnded(touch: touch)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(UIColor.init(red: 20.0/255.0, green: 119.0/255.0, blue: 234.0/255.0, alpha: 0.75).cgColor)
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        self.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
}
