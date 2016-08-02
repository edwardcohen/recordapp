//
//  CodeCellView.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CodeCellView: JTAppleDayCellView {
    let bgColor = UIColor.redColor()
    

    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        
//        print("superview: \(self.frame)")
//        print("loal rect: \(rect)\n")
        
        let context = UIGraphicsGetCurrentContext();
        
        CGContextSetRGBFillColor(context, 1.0, 0.5, 0.0, 1.0);
        let r1 = CGRectMake(0 , 0, 25, 25);         // Size
        CGContextAddRect(context,r1);
        CGContextFillPath(context);
        
        CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0.5, 1.0);
        CGContextAddEllipseInRect(context, CGRectMake(0 , 0, 25, 25));
        CGContextStrokePath(context);
    }
}
