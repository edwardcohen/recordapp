//
//  TagCellView.swift
//  VoiceRecorder
//
//  Created by developer on 8/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class TagCellView: UICollectionViewCell {
    @IBOutlet var tagLabel: UILabel!
    
    @IBOutlet weak var tagLabelMaxWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 4
        
        self.tagLabelMaxWidthConstraint.constant = UIScreen.mainScreen().bounds.width - 8 * 2 - 8 * 2
    }
}
