//
//  TagCellView.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/10/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import UIKit

class TagCellView: UICollectionViewCell {
    @IBOutlet var tagLabel: UILabel!
    
    @IBOutlet weak var tagLabelMaxWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        self.backgroundColor = UIColor.lightGrayColor()
        self.tagLabel.textColor = UIColor.whiteColor()
        self.layer.cornerRadius = 4
        
        self.tagLabelMaxWidthConstraint.constant = UIScreen.mainScreen().bounds.width - 8 * 2 - 8 * 2
    }
}
