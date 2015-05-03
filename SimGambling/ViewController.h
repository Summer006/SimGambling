//
//  ViewController.h
//  SimGambling
//
//  Created by Xia Summer on 15/2/18.
//  Copyright (c) 2015年 Xia Summer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>



@property (nonatomic) IBOutlet NSTableView * _resultTable;
@property (nonatomic) IBOutlet NSTableView * _detailTable;
@property (nonatomic) IBOutlet NSView * _lineChart;



-(IBAction)onTestClicked:(id)sender;

@end

