//
//  TableCellView.swift
//  VoiceRecorder
//
//  Created by developer on 8/4/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation

class VoiceTableCellView: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var lengthLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var tagView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var playButton: UIButton!
    
    
    @IBOutlet weak var detailView: UIView!
    
    
    var tags = [String]()
    
    var sizingCell: TagCellView?
    
    var voiceFileURL : NSURL?
    
    var audioPlayer: AVAudioPlayer?
    
    var timer: NSTimer?

    var session:AVAudioSession?
    
    var isPlaying = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tagView.dataSource = self
        tagView.delegate = self
        
        let cellNib = UINib(nibName: "TagCellView", bundle: nil)
        self.tagView.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagView.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCellView?
        tagView.reloadData()
        print("Called VoiceTableCellView awakeFromNib()")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            initAudioPlayer()
        } else {
            stopAudioPlayer()
        }
    }
    
    func initAudioPlayer() {
        session = AVAudioSession.sharedInstance()
        try! session!.setCategory(AVAudioSessionCategoryPlayback)
        try! session!.setActive(true)
        
        if let fileURL = voiceFileURL {
            let audioFileName = fileURL.lastPathComponent
            let documentDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let soundFileURL = documentDirectory.URLByAppendingPathComponent(audioFileName!)
            
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(soundFileURL.path!) {
                print("File Avaliable")
                do {
                    audioPlayer = nil
                    try audioPlayer = AVAudioPlayer(contentsOfURL: soundFileURL, fileTypeHint: AVFileTypeAppleM4A)
                    audioPlayer!.prepareToPlay()
                    audioPlayer!.volume = 0.5
                } catch {
                    print("error initializing AVAudioPlayer: \(error)")
                }
            } else {
                print("File Not Avaliable")
            }
            
        }
        
    }
    
    func stopAudioPlayer() {
        if let player = audioPlayer {
            player.stop()
        }
        audioPlayer = nil
        timer?.invalidate()
        progressView.progress = 0
        isPlaying = false
        playButton.setBackgroundImage(UIImage(named: "play.png"), forState: .Normal)
    }
    
    @IBAction func playVoiceAction(sender: AnyObject) {
        if let player = audioPlayer {
            player.delegate = self
            if isPlaying {
                player.pause()
                playButton.setBackgroundImage(UIImage(named: "play.png"), forState: .Normal)
                isPlaying = false
            } else {
                player.play()
                startTimer()
                isPlaying = true
                playButton.setBackgroundImage(UIImage(named: "pause.png"), forState: .Normal)
            }
        }
        
    }

    func startTimer() {
        timer = NSTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: "NSDefaultRunLoopMode")
    }
    
    func stopTimer() {
        if timer != nil {
            timer!.invalidate()
        }
        timer = nil
    }
    
    func updateProgress() {
        if let player = audioPlayer {
            player.updateMeters()
            let progress = Float(audioPlayer!.currentTime/audioPlayer!.duration)
            progressView.progress = progress > 0.98 ? 1: progress
        }
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

extension VoiceTableCellView:AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        stopAudioPlayer()
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        stopTimer()
    }
}