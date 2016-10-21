//
//  VoiceTableViewController.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import JTAppleCalendar
import CloudKit
import UIKit
import CoreData
import MapKit

class VoiceTableViewController: UIViewController, NSFetchedResultsControllerDelegate, PulleyDrawerViewControllerDelegate {
//    var voiceRecords:[CKRecord] = []
    var voiceRecords:[Voice] = []
    var originRecords:[Voice] = []
    var fetchResultController:NSFetchedResultsController!
    
    var audioFileURL: NSURL?
    
    @IBOutlet var monthButton: UIButton!
    @IBOutlet var yearButton: UIButton!
    @IBOutlet var calendarView: JTAppleCalendarView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tagView: UICollectionView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var calendarViewHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var weekDaysStackView: UIStackView!
    
    let formatter = NSDateFormatter()
    let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    
    var tags = [String]()
    var sizingCell: TagCellView?
    var selectedCellIndexPath:NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()

        getVoiceRecordsFromCoreData() { (success: Bool) -> Void in
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
//        getRecordsFromCloud() { (success: Bool) -> Void in
//            if success {
//                NSOperationQueue.mainQueue().addOperationWithBlock() {
//                    self.spinner.stopAnimating()
//                    self.calendarView.reloadData()
//                    self.calendarView.selectDates([NSDate()], triggerSelectionDelegate: true)
//                    self.getTagsFromRecords()
//                    self.tagView.reloadData()
//                    self.tableView.reloadData()
//                }
//            }
//        }
        
        formatter.dateFormat = "yyyy MM dd"
        calendar.timeZone = NSTimeZone(abbreviation: "GMT")!

        calendarView.delegate = self
        calendarView.dataSource = self
        
//        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.registerCellViewXib(fileName: "CalendarCellView")
        calendarView.direction = .Horizontal                       // default is horizontal
        calendarView.cellInset = CGPoint(x: 0, y: 0)               // default is (3,3)
        calendarView.allowsMultipleSelection = false               // default is false
        calendarView.firstDayOfWeek = .Sunday                      // default is Sunday
        calendarView.scrollEnabled = true                          // default is true
        calendarView.scrollingMode = .StopAtEachCalendarFrameWidth // default is .StopAtEachCalendarFrameWidth
        calendarView.itemSize = nil                                // default is nil. Use a value here to change the size of your cells
        calendarView.reloadData()
        
        // After reloading. Scroll to your selected date, and setup your calendar
        calendarView.scrollToDate(NSDate(), triggerScrollToDateDelegate: false, animateScroll: false) {
            let currentDate = self.calendarView.currentCalendarDateSegment().dateRange
            self.setupViewsOfCalendar(currentDate.start, endDate: currentDate.end)
        }
        
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
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
    
    @IBAction func onClickMonthButton(sender: AnyObject) {
        if self.calendarViewHeightContraint.constant == 0 {
            UIView.animateWithDuration(0.5, animations: {
                self.weekDaysStackView.hidden = false
                self.calendarViewHeightContraint.constant = 200
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animateWithDuration(0.5, animations: {
                self.weekDaysStackView.hidden = true
                self.calendarViewHeightContraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func onClickYearButton(sender: AnyObject) {
        if self.calendarViewHeightContraint.constant == 0 {
            UIView.animateWithDuration(0.5, animations: {
                self.weekDaysStackView.hidden = false
                self.calendarViewHeightContraint.constant = 200
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animateWithDuration(0.5, animations: {
                self.weekDaysStackView.hidden = true
                self.calendarViewHeightContraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupViewsOfCalendar(startDate: NSDate, endDate: NSDate) {
        let month = calendar.component(NSCalendarUnit.Month, fromDate: endDate)
        let monthName = NSDateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array
        let year = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: endDate)
        monthButton.setTitle(String(monthName), forState: UIControlState.Normal)
        yearButton.setTitle(String(year), forState: UIControlState.Normal)
    }
    
//    func getRecordsFromCloud(completionHandler: (Bool) -> Void) {
//        // Fetch data using Operational API
//        let cloudContainer = CKContainer.defaultContainer()
//        let publicDatabase = cloudContainer.publicCloudDatabase
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "Voice", predicate: predicate)
//        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//        
//        // Create the query operation with the query
//        let queryOperation = CKQueryOperation(query: query)
//        queryOperation.desiredKeys = ["title", "length", "date", "location", "tags", "marks"]
//        queryOperation.queuePriority = .VeryHigh
//        queryOperation.resultsLimit = 50
//        queryOperation.recordFetchedBlock = { (record:CKRecord!) -> Void in
//            if let voiceRecord = record {
//                self.voiceRecords.append(voiceRecord)
//            }
//        }
    
//        queryOperation.queryCompletionBlock = { (cursor:CKQueryCursor?, error:NSError?) -> Void in
//            if (error != nil) {
//                print("Failed to get data from iCloud - \(error!.localizedDescription)")
//                completionHandler(false)
//                return
//            }
//            
//            print("Retrieved data from iCloud")
//            completionHandler(true)
//        }
    
        // Execute the query
//        publicDatabase.addOperation(queryOperation)
//    }
    
    func getVoiceRecordsFromCoreData(completionHandler: (Bool) -> Void) {
        // Load the voices from database
        let fetchRequest = NSFetchRequest(entityName:"Voice")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let managedObjectContext = (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext {
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
            
            do {
                try fetchResultController.performFetch()
                voiceRecords = fetchResultController.fetchedObjects as! [Voice]
                print("Retrived data from core data")
                completionHandler(true)
            } catch {
                print("Failed to get data from core data - \(error)")
                completionHandler(false)
            }
        }
        
    }
    
    func getTagsFromRecords() {
        var tags = [String]()
        for voiceRecord in voiceRecords {
//            if let recordTags = voiceRecord.objectForKey("tags") as? [String] {
              if let recordTags = voiceRecord.tags {
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
    
    // MARK: - Navigation
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showVoiceDetail" {
//            if let indexPath = tableView.indexPathForSelectedRow {
//                let destinationController = segue.destinationViewController as! VoiceDetailViewController
//                let voiceRecord = voiceRecords[indexPath.row]
//                destinationController.voice = voiceRecord
//            }
//        }
//    }
    
    func getDocumentsDirectoryURL() -> NSURL {
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return URLs[0]
    }
    
//    func getAudioFromCloud(voiceRecord: CKRecord, completionHandler: (Bool, NSURL?) -> Void) {
//        // Fetch Audio from Cloud in background
//        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
//        let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs:
//            [voiceRecord.recordID])
//        fetchRecordsImageOperation.desiredKeys = ["audio"]
//        fetchRecordsImageOperation.queuePriority = .VeryHigh
//        fetchRecordsImageOperation.perRecordCompletionBlock = {(record:CKRecord?,
//            recordID:CKRecordID?, error:NSError?) -> Void in
//            if (error != nil) {
//                print("Failed to get voice audio: \(error!.localizedDescription)")
//                completionHandler(false, nil)
//                return
//            }
//            if let voiceRecord = record {
//                NSOperationQueue.mainQueue().addOperationWithBlock() {
//                    if let audioAsset = voiceRecord.objectForKey("audio") as? CKAsset {
//                        completionHandler(true, audioAsset.fileURL)
//                    }
//                }
//            } else {
//                completionHandler(false, nil)
//            }
//            
//        } 
//        publicDatabase.addOperation(fetchRecordsImageOperation)
//    }
    
    func getAudioFromCoreData(voiceRecord: Voice, completionHandler: (Bool, NSURL?) -> Void) {
        // Fetch Audio from Core Data in background
        if voiceRecord.audio.absoluteString != "" {
            completionHandler(true, voiceRecord.audio)
        } else {
            print("Failed to get voice audio")
            completionHandler(false, nil)
        }
    }
    
    // MARK: -NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            if let _newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([_newIndexPath], withRowAnimation: .Fade)
            }
        case .Delete:
            if let _indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([_indexPath], withRowAnimation: .Fade)
            }
        case .Update:
            if let _indexPath = indexPath {
                tableView.reloadRowsAtIndexPaths([_indexPath], withRowAnimation: .Fade)
            }
            
        default:
            tableView.reloadData()
        }
        
        voiceRecords = controller.fetchedObjects as! [Voice]
        originRecords = voiceRecords
        self.getTagsFromRecords()
        tagView.reloadData()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.insertSections(sectionIndexSet, withRowAnimation: .Fade)
        case .Delete:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.deleteSections(sectionIndexSet, withRowAnimation: .Fade)
            
        default:
            tableView.reloadData()
        }
        voiceRecords = controller.fetchedObjects as! [Voice]
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    // MARK: Drawer Content View Controller Delegate
    
    func collapsedDrawerHeight() -> CGFloat
    {
        return 38.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return 300.0
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
            NSCalendar.currentCalendar().compareDate(($0.date), toDate: date, toUnitGranularity: .Day)==NSComparisonResult.OrderedSame}) {
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
        
        let curCalendar = NSCalendar.currentCalendar()
//        curCalendar.timeZone = NSTimeZone(abbreviation: "UTC")!
        let startOfDay = curCalendar.startOfDayForDate(date)

        let components = NSDateComponents()
        components.hour = 23
        components.minute = 59
        components.second = 59
        let endOfDay = curCalendar.dateByAddingComponents(components, toDate: startOfDay, options: NSCalendarOptions(rawValue: 0))
        
        let predicate = NSPredicate(format: "(date >= %@) AND (date <=%@)", startOfDay, endOfDay!)
        self.fetchResultController.fetchRequest.predicate = predicate
        do {
            try self.fetchResultController.performFetch()
            voiceRecords = fetchResultController.fetchedObjects as! [Voice]
            originRecords = voiceRecords
            self.tableView.reloadData()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }
    
    func calendar(calendar: JTAppleCalendarView, isAboutToResetCell cell: JTAppleDayCellView) {
        (cell as? CalendarCellView)?.selectedView.hidden = true
    }
    
    func calendar(calendar: JTAppleCalendarView, didScrollToDateSegmentStartingWithdate startDate: NSDate, endingWithDate endDate: NSDate) {
        setupViewsOfCalendar(startDate, endDate: endDate)
    }
}

// MARK : UITableViewDelegate
extension VoiceTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voiceRecords.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "VoiceTableCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! VoiceTableCellView
        
        // Configure the cell...
        let voiceRecord = voiceRecords[indexPath.row]
        
        cell.titleLabel.text = voiceRecord.title //voiceRecord.objectForKey("title") as? String
        cell.lengthLabel.text = String(voiceRecord.length) //String(voiceRecord.objectForKey("length") as! Int)
        
        let date = voiceRecord.date //voiceRecord.objectForKey("date") as! NSDate
        let dateformatter = NSDateFormatter()
        dateformatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let datestring = dateformatter.stringFromDate(date)
        cell.dateLabel.text = String(datestring)
        
        cell.tags = voiceRecord.tags! //voiceRecord.objectForKey("tags") as! [String]

        let annotation = MKPointAnnotation()
        annotation.coordinate = voiceRecord.location.coordinate
        cell.mapView.showAnnotations([annotation], animated: true)
        cell.mapView.selectAnnotation(annotation, animated: true)

        cell.voiceFileURL = voiceRecord.audio
        
        cell.backgroundColor = UIColor.clearColor()
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = backgroundView
        
        cell.tagView.reloadData()
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if selectedCellIndexPath == indexPath {
            return 240
        }
        return 67
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.beginUpdates()
        if selectedCellIndexPath != nil && selectedCellIndexPath == indexPath {
            selectedCellIndexPath = nil
        } else {
            selectedCellIndexPath = indexPath
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.endUpdates()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        UIView.animateWithDuration(0.5, animations: {
            self.weekDaysStackView.hidden = true
            self.calendarViewHeightContraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
}

// MARK : UICollectionViewDelegate, UICollectionViewDataSource
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
        print("Selected Tag ---> \(tags[indexPath.item])")
        voiceRecords = originRecords.filter() {
            if let curtags = ($0 as Voice).tags as [String]! {
                return curtags.contains(tags[indexPath.item])
            } else {
                return false
            }
        }
        self.tableView.reloadData()
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