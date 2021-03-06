//
//  PNLineChart.h
//  PNChartDemo
//
//  Created by kevin on 11/7/13.
//  Copyright (c) 2013年 kevinzhow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "PNChartDelegate.h"

@interface PNLineChart : NSView

/**
 * Draws the chart in an animated fashion.
 */
- (void)strokeChart;
- (void)strokeChartWithoutAnim;

@property (nonatomic, retain) id<PNChartDelegate> delegate;

@property (nonatomic) NSArray *xLabels;
@property (nonatomic) NSArray *yLabels;

/**
 * Array of `LineChartData` objects, one for each line.
 */
@property (nonatomic) NSArray *chartData;

@property (nonatomic) NSMutableArray *pathPoints;
@property (nonatomic) NSMutableArray *xChartLabels;
@property (nonatomic) NSMutableArray *yChartLabels;

@property (nonatomic) CGFloat xLabelWidth;
@property (nonatomic) NSFont *xLabelFont;
@property (nonatomic) NSColor *xLabelColor;
@property (nonatomic) CGFloat yValueMax;
@property (nonatomic) CGFloat yFixedValueMax;
@property (nonatomic) CGFloat yFixedValueMin;
@property (nonatomic) CGFloat yValueMin;
@property (nonatomic) NSInteger yLabelNum;
@property (nonatomic) CGFloat yLabelHeight;
@property (nonatomic) NSFont *yLabelFont;
@property (nonatomic) NSColor *yLabelColor;
@property (nonatomic) CGFloat chartCavanHeight;
@property (nonatomic) CGFloat chartCavanWidth;
@property (nonatomic) CGFloat chartMargin;
@property (nonatomic) BOOL showLabel;

/**
 * Controls whether to show the coordinate axis. Default is NO.
 */
@property (nonatomic, getter = isShowCoordinateAxis) BOOL showCoordinateAxis;
@property (nonatomic) NSColor *axisColor;
@property (nonatomic) CGFloat axisWidth;

@property (nonatomic, strong) NSString *xUnit;
@property (nonatomic, strong) NSString *yUnit;

/**
 * String formatter for float values in y-axis labels. If not set, defaults to @"%1.f"
 */
@property (nonatomic, strong) NSString *yLabelFormat;

- (void)setXLabels:(NSArray *)xLabels withWidth:(CGFloat)width;

/**
 * Update Chart Value
 */

- (void)updateChartData:(NSArray *)data;

@end
