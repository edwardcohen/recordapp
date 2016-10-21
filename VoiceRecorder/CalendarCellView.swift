//
//  CellView.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import JTAppleCalendar

class CalendarCellView: JTAppleDayCellView {
    @IBInspectable var todayColor: UIColor!// = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.3)
    @IBInspectable var normalDayColor: UIColor! //UIColor(white: 0.0, alpha: 0.1)
    @IBOutlet var selectedView: AnimationView!
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var dotLabel: UILabel!
    
    let textSelectedColor = UIColor(red:0x00/255, green:0x7A/255, blue:0xFF/255, alpha:1.0)
    let textDeselectedColor = UIColor(red:0x00/255, green:0x7A/255, blue:0xFF/255, alpha:1.0)
    let previousMonthTextColor = UIColor.grayColor()
    lazy var todayDate : String = {
        [weak self] in
        let aString = self!.c.stringFromDate(NSDate())
        return aString
    }()
    lazy var c : NSDateFormatter = {
        let f = NSDateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        
        return f
    }()
    
    func setupCellBeforeDisplay(cellState: CellState, date: NSDate, indicator: Bool) {
        // Setup Cell text
        dayLabel.text =  cellState.text
        
        // Setup text color
        configureTextColor(cellState)

        // Setup cell selection status
        delayRunOnMainThread(0.0) {
            self.configueViewIntoBubbleView(cellState)
        }
    
        // Configure Visibility
        configureVisibility(cellState)
        
        // Configure Indicator
        dotLabel.hidden = !indicator
        
        // With cell states you can literally control every aspect of the calendar view
        // Uncomment this code block to watch "JTAPPLE" spelt on the calendar
//        let dateSection = c.stringFromDate(cellState.dateSection().startDate)
//        if dateSection == "2016-01-01" && (cellState.row() == 0 || cellState.column() == 3 || (cellState.row() == 5 && cellState.column() < 4)) {
//            self.backgroundColor = UIColor.redColor()
//        } else if dateSection == "2016-02-01" && (cellState.row() == 0 || cellState.column() == 3) {
//            self.backgroundColor = UIColor.redColor()
//        } else if dateSection == "2016-03-01" && (cellState.column() == 0 || cellState.column() == 6 || cellState.row() == 2 || cellState.row() == 0) {
//            self.backgroundColor = UIColor.redColor()
//        } else if dateSection == "2016-04-01" && (cellState.column() == 0 || (cellState.column() == 6 && cellState.row() < 3) || cellState.row() == 2 || cellState.row() == 0) {
//            self.backgroundColor = UIColor.redColor()
//        } else if dateSection == "2016-05-01" && (cellState.column() == 0 || (cellState.column() == 6 && cellState.row() < 3) || cellState.row() == 2 || cellState.row() == 0) {
//            self.backgroundColor = UIColor.redColor()
//        } else if dateSection == "2016-06-01" && (cellState.column() == 0 || cellState.row() == 5) {
//            self.backgroundColor = UIColor.redColor()
//        }
    }
    
    func configureVisibility(cellState: CellState) {
        if cellState.dateBelongsTo == .ThisMonth {
            self.hidden = false
        } else {
            self.hidden = true
        }
        
    }
    
    func configureTextColor(cellState: CellState) {
        if cellState.isSelected {
            dayLabel.textColor = textSelectedColor
        } else if cellState.dateBelongsTo == .ThisMonth {
            dayLabel.textColor = textDeselectedColor
        } else {
            dayLabel.textColor = previousMonthTextColor
        }
    }
    
    func cellSelectionChanged(cellState: CellState) {
        if cellState.isSelected == true {
            if selectedView.hidden == true {
                configueViewIntoBubbleView(cellState)
                selectedView.animateWithBounceEffect(withCompletionHandler: {
                })
            }
        } else {
            configueViewIntoBubbleView(cellState, animateDeselection: true)
        }
    }
    
    private func configueViewIntoBubbleView(cellState: CellState, animateDeselection: Bool = false) {
        if cellState.isSelected {
            self.selectedView.layer.cornerRadius =  self.selectedView.frame.width  / 2
            self.selectedView.hidden = false
            configureTextColor(cellState)
            
        } else {
            if animateDeselection {
                configureTextColor(cellState)
                if selectedView.hidden == false {
                    selectedView.animateWithFadeEffect(withCompletionHandler: { () -> Void in
                        self.selectedView.hidden = true
                        self.selectedView.alpha = 1
                    })
                }
            } else {
                selectedView.hidden = true
            }
        }
    }
}

class AnimationView: UIView {

    func animateWithFlipEffect(withCompletionHandler completionHandler:(()->Void)?) {
        AnimationClass.flipAnimation(self, completion: completionHandler)
    }
    func animateWithBounceEffect(withCompletionHandler completionHandler:(()->Void)?) {
        let viewAnimation = AnimationClass.BounceEffect()
        viewAnimation(self){ _ in
            completionHandler?()
        }
    }
    func animateWithFadeEffect(withCompletionHandler completionHandler:(()->Void)?) {
        let viewAnimation = AnimationClass.FadeOutEffect()
        viewAnimation(self) { _ in
            completionHandler?()
        }
    }
}