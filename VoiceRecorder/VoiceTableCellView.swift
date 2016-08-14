//
//  TableCellView.swift
//  VoiceRecorder
//
//  Created by developer on 8/4/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class VoiceTableCellView: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var lengthLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var tagView: UICollectionView!
    
    var tags = [String]()
    
    var sizingCell: TagCellView?

    override func awakeFromNib() {
        super.awakeFromNib()

        tagView.dataSource = self
        tagView.delegate = self
        
        tagView.reloadData()
        
        let cellNib = UINib(nibName: "TagCellView", bundle: nil)
        self.tagView.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagView.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCellView?
    }
}

extension VoiceTableCellView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let tagCell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCell", forIndexPath: indexPath) as! TagCellView
        self.configureCell(tagCell, forIndexPath: indexPath)
        return tagCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        self.configureCell(self.sizingCell!, forIndexPath: indexPath)
        return self.sizingCell!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
    
    func configureCell(cell: TagCellView, forIndexPath indexPath: NSIndexPath) {
        cell.tagLabel.text = tags[indexPath.item]
    }
}