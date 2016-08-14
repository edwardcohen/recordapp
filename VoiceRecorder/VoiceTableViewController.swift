//
//  VoiceTableViewController.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import JTAppleCalendar
import CloudKit

class VoiceTableViewController: UIViewController {
    var voiceRecords:[CKRecord] = []
    var audioFileURL: NSURL?
    
    @IBOutlet var monthButton: UIButton!
    @IBOutlet var yearButton: UIButton!
    @IBOutlet var calendarView: JTAppleCalendarView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tagView: UICollectionView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    let formatter = NSDateFormatter()
    let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    
    var tags = [String]()
    var sizingCell: TagCellView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()

        getRecordsFromCloud() { (success: Bool) -> Void in
            if success {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.spinner.stopAnimating()
                    self.calendarView.reloadData()
                    self.calendarView.selectDates([NSDate()], triggerSelectionDelegate: true)
                    self.getTagsFromRecords()
                    self.tagView.reloadData()
                    self.tableView.reloadData()
                }
            }
        }
        
        formatter.dateFormat = "yyyy MM dd"
        calendar.timeZone = NSTimeZone(abbreviation: "GMT")!

        calendarView.delegate = self
        calendarView.dataSource = self
        
        calendarView.registerCellViewXib(fileName: "CalendarCellView")
        calendarView.direction = .Horizontal                       // default is horizontal
        calendarView.cellInset = CGPoint(x: 0, y: 0)               // default is (3,3)
        calendarView.allowsMultipleSelection = false               // default is false
        calendarView.bufferTop = 0                                 // default is 0. - still work in progress on this
        calendarView.bufferBottom = 0                              // default is 0. - still work in progress on this
        calendarView.firstDayOfWeek = .Sunday                      // default is Sunday
        calendarView.scrollEnabled = true                          // default is true
        calendarView.pagingEnabled = true                          // default is true
        calendarView.scrollResistance = 0.75                       // default is 0.75 - this is only applicable when paging is not enabled.
        calendarView.itemSize = nil                                // default is nil. Use a value here to change the size of your cells
        calendarView.cellSnapsToEdge = true                        // default is true. Disabling this causes calendar to not snap to grid
        calendarView.reloadData()
        
        // After reloading. Scroll to your selected date, and setup your calendar
        calendarView.scrollToDate(NSDate(), triggerScrollToDateDelegate: false, animateScroll: false) {
            let currentDate = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(currentDate.startDate, endDate: currentDate.endDate)
        }
        
        tableView.backgroundColor = UIColor.clearColor()
        
        tagView.delegate = self
        tagView.dataSource = self
        
        let cellNib = UINib(nibName: "TagCellView", bundle: nil)
        self.tagView.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagView.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCellView?
    }
    
    @IBAction func scrollToDate(sender: AnyObject?) {
        let date = formatter.dateFromString("2016 03 11")
        calendarView.scrollToDate(date!)
    }
    
    @IBAction func printSelectedDates() {
        print("Selected dates --->")
        for date in calendarView.selectedDates {
            print(formatter.stringFromDate(date))
        }
    }

    @IBAction func next(sender: UIButton) {
        self.calendarView.scrollToNextSegment()
        
    }
    @IBAction func previous(sender: UIButton) {
        self.calendarView.scrollToPreviousSegment()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupViewsOfCalendar(startDate: NSDate, endDate: NSDate) {
        let month = calendar.component(NSCalendarUnit.Month, fromDate: endDate)
        let monthName = NSDateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array
        let year = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: endDate)
        monthButton.setTitle(String(monthName), forState: UIControlState.Normal)
        yearButton.setTitle(String(year), forState: UIControlState.Normal)    }
    
    func getRecordsFromCloud(completionHandler: (Bool) -> Void) {
        // Fetch data using Operational API
        let cloudContainer = CKContainer.defaultContainer()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Voice", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Create the query operation with the query
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["title", "length", "date", "location", "tags", "marks"]
        queryOperation.queuePriority = .VeryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordFetchedBlock = { (record:CKRecord!) -> Void in
            if let voiceRecord = record {
                self.voiceRecords.append(voiceRecord)
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor:CKQueryCursor?, error:NSError?) -> Void in
            if (error != nil) {
                print("Failed to get data from iCloud - \(error!.localizedDescription)")
                completionHandler(false)
                return
            }
            
            print("Retrieved data from iCloud")
            completionHandler(true)
        }
        
        // Execute the query
        publicDatabase.addOperation(queryOperation)
    }
    
    func getTagsFromRecords() {
        var tags = [String]()
        for voiceRecord in voiceRecords {
            if let recordTags = voiceRecord.objectForKey("tags") as? [String] {
                for recordTag in recordTags {
                    tags.append(recordTag)
                }
            }
        }
        print(tags)
        
        // Sort by frequency
        var tagFrequencies = [String: Int]()
        for tag in tags {
            if tagFrequencies[tag] == nil {
                tagFrequencies[tag] = 1
            } else {
                tagFrequencies[tag] = tagFrequencies[tag]! + 1
            }
        }
        print(tagFrequencies)
        
        var sortedTags = Array(tagFrequencies.keys)
        sortedTags.sortInPlace({ tagFrequencies[$0] > tagFrequencies[$1] })
        print(sortedTags)
        
        self.tags = sortedTags
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showVoiceDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destinationViewController as! VoiceDetailViewController
                let voiceRecord = voiceRecords[indexPath.row]
                
                let title = voiceRecord.objectForKey("title") as? String
                let length = voiceRecord.objectForKey("length") as! Int
                let tags = voiceRecord.objectForKey("tags") as? [String]
                let date = voiceRecord.objectForKey("date") as! NSDate
                let marks = voiceRecord.objectForKey("marks") as? [Int]
                let location = voiceRecord.objectForKey("location") as! CLLocation
                
                destinationController.voice = Voice(title: title, length: length, date: date, tags: tags, location: location, marks: marks, audio: audioFileURL!)
            }
        }
    }
    
    func getDocumentsDirectoryURL() -> NSURL {
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return URLs[0]
    }
    
    func getAudioFromCloud(voiceRecord: CKRecord, completionHandler: (Bool, NSURL?) -> Void) {
        // Fetch Audio from Cloud in background
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs:
            [voiceRecord.recordID])
        fetchRecordsImageOperation.desiredKeys = ["audio"]
        fetchRecordsImageOperation.queuePriority = .VeryHigh
        fetchRecordsImageOperation.perRecordCompletionBlock = {(record:CKRecord?,
            recordID:CKRecordID?, error:NSError?) -> Void in
            if (error != nil) {
                print("Failed to get voice audio: \(error!.localizedDescription)")
                completionHandler(false, nil)
                return
            }
            if let voiceRecord = record {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    if let audioAsset = voiceRecord.objectForKey("audio") as? CKAsset {
                        completionHandler(true, audioAsset.fileURL)
                    }
                }
            } else {
                completionHandler(false, nil)
            }
            
        } 
        publicDatabase.addOperation(fetchRecordsImageOperation)
    }
}

// MARK : JTAppleCalendarDelegate
extension VoiceTableViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func configureCalendar(calendar: JTAppleCalendarView) -> (startDate: NSDate, endDate: NSDate, numberOfRows: Int, calendar: NSCalendar) {
        
        let firstDate = formatter.dateFromString("2016 01 01")
        let secondDate = NSDate()
        let aCalendar = NSCalendar.currentCalendar() // Properly configure your calendar to your time zone here
        return (startDate: firstDate!, endDate: secondDate, numberOfRows: 6, calendar: aCalendar)
    }

    func calendar(calendar: JTAppleCalendarView, isAboutToDisplayCell cell: JTAppleDayCellView, date: NSDate, cellState: CellState) {
        var hasVoice = false
        if let _ = voiceRecords.indexOf({
            NSCalendar.currentCalendar().compareDate(($0.objectForKey("date") as! NSDate), toDate: date, toUnitGranularity: .Day)==NSComparisonResult.OrderedSame}) {
            hasVoice = true
        }
        (cell as? CalendarCellView)?.setupCellBeforeDisplay(cellState, date: date, indicator: hasVoice)
    }

    func calendar(calendar: JTAppleCalendarView, didDeselectDate date: NSDate, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CalendarCellView)?.cellSelectionChanged(cellState)
    }
    
    func calendar(calendar: JTAppleCalendarView, didSelectDate date: NSDate, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CalendarCellView)?.cellSelectionChanged(cellState)
        printSelectedDates()
    }
    
    func calendar(calendar: JTAppleCalendarView, isAboutToResetCell cell: JTAppleDayCellView) {
        (cell as? CalendarCellView)?.selectedView.hidden = true
    }
    
    func calendar(calendar: JTAppleCalendarView, didScrollToDateSegmentStartingWithdate startDate: NSDate, endingWithDate endDate: NSDate) {
        setupViewsOfCalendar(startDate, endDate: endDate)
    }
}

extension VoiceTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voiceRecords.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "VoiceTableCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! VoiceTableCellView
        
        // Configure the cell...
        let voiceRecord = voiceRecords[indexPath.row]
        
        cell.titleLabel.text = voiceRecord.objectForKey("title") as? String
        cell.lengthLabel.text = String(voiceRecord.objectForKey("length") as! Int)
        
        let date = voiceRecord.objectForKey("date") as! NSDate
        let dateformatter = NSDateFormatter()
        dateformatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateformatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let datestring = dateformatter.stringFromDate(date)
        cell.dateLabel.text = String(datestring)
        
        cell.tags = voiceRecord.objectForKey("tags") as! [String]
        
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let voiceRecord = voiceRecords[indexPath.row]
        
        getAudioFromCloud(voiceRecord) {(success: Bool, audioFileURL: NSURL?) -> Void in
            if success {
                self.audioFileURL = audioFileURL!
                self.performSegueWithIdentifier("showVoiceDetail", sender: self)
            }
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? VoiceTableCellView else { return }
        
        tableViewCell.tagView.reloadData()
//        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
    }
    
}

extension VoiceTableViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("Selected TAG ---> \(tags[indexPath.item])")
    }
}

func delayRunOnMainThread(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}