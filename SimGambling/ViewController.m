//
//  ViewController.m
//  SimGambling
//
//  Created by Xia Summer on 15/2/18.
//  Copyright (c) 2015年 Xia Summer. All rights reserved.
//

#import "ViewController.h"
#import "PNChart.h"

typedef enum : NSUInteger {
    BetTypeBig,
    BetTypeSmall,
    BetTypeDraw,
} BetType;




@implementation ViewController {
    int _gamblingCount;
    int _totalMoney;
    int _eachBetting;
    
    int _simRoundCount;
    int _targetWin;
    
    BOOL _hasMaxBetting;
    int _maxBetting;
    float _multiple;
    
    NSMutableArray * _result;
    int _roundIndex;
    
    NSMutableDictionary * _summary;
}

@synthesize _resultTable;
@synthesize _detailTable;
@synthesize _lineChart;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_resultTable setDelegate:self];
    [_resultTable setDataSource:self];
//    [_detailTable setDelegate:self];
    [_detailTable setDataSource:self];
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


-(IBAction)onTestClicked:(id)sender {
    _gamblingCount =  ((NSTextField*)[self.view viewWithTag:101]).intValue;
    _totalMoney =  ((NSTextField*)[self.view viewWithTag:102]).intValue;
    _eachBetting =  ((NSTextField*)[self.view viewWithTag:103]).intValue;
    _simRoundCount =  ((NSTextField*)[self.view viewWithTag:104]).intValue;
    _targetWin =  ((NSTextField*)[self.view viewWithTag:105]).intValue;
    _hasMaxBetting = ((NSButton*)[self.view viewWithTag:106]).state;
    _maxBetting =  ((NSTextField*)[self.view viewWithTag:107]).intValue;
    _multiple = ((NSTextField*)[self.view viewWithTag:108]).floatValue;
    
    [ViewController runBlockInBackground:^{
        [self beginSimGambling];
    } afterDelay:0];
    
}

-(void)beginSimGambling {
    if (_result!=nil) {
        [_result removeAllObjects];
        _result = nil;
        _summary = nil;
    }
    _result = [[NSMutableArray alloc] init];
    _summary = [[NSMutableDictionary alloc] init];
    for (int t=0; t<_simRoundCount; t++) {
        [self simOneRoundGambling:t];
        
        if (t>0 && t%50==0) {
            [self calculateSummary];
            [ViewController runBlockInMainQueue:^{
                [_resultTable reloadData];
                //[self drawLineChart];
                //[_resultTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            } afterDelay:0];
        }
    }
    [ViewController runBlockInMainQueue:^{
        [self calculateSummary];
        [_resultTable reloadData];
        _roundIndex = 0;
        [_detailTable reloadData];
    } afterDelay:0];
}

-(void)calculateSummary {
    int loseCount = 0;
    int winCount = 0;
    int winTargetCount = 0;
    int minMoney = _totalMoney;
    NSInteger totalWin = 0;
    NSUInteger sumMinMoney = 0;
    for (int t=0; t<_result.count; t++) {
        NSDictionary * round = [_result objectAtIndex:t];
        int restMoney = [[round objectForKey:@"Rest"] intValue];
        int winMoney = [[round objectForKey:@"WinMoney"] intValue];
        totalWin+=winMoney;
        if (restMoney==0) loseCount++;
        if (winMoney>0) {
            winCount++;
            if (winMoney>=_targetWin) winTargetCount++;
            int miniMoney = [[round objectForKey:@"MinMoney"] intValue];
            if (miniMoney<minMoney) minMoney = miniMoney;
            sumMinMoney += miniMoney;
        }
    }
    float rateLose = (float)loseCount / _result.count;
    float rateWin = (float)winCount / _result.count;
    float rateWinTarget = (float)winTargetCount / _result.count;
    float maxLost = (float)(_totalMoney - minMoney) / _totalMoney;
    float avgLost = winCount>0 ? (float)(_totalMoney - sumMinMoney / winCount) / _totalMoney : 0;
    [_summary setObject:@"Summary" forKey:@"RoundNo"];
    [_summary setObject:[NSString stringWithFormat:@"L=%2.2f%%", rateLose*100.0] forKey:@"Rest"];
    [_summary setObject:[NSString stringWithFormat:@"W=%2.2f%%", rateWin*100.0] forKey:@"WinMoney"];
    [_summary setObject:[NSString stringWithFormat:@"WT=%2.1f%%", rateWinTarget*100.0] forKey:@"WinCount"];
    [_summary setObject:[NSString stringWithFormat:@"A=%2.f%%,M=%2.f%%", avgLost*100.0, maxLost*100.0] forKey:@"MaxLost"];
    [_summary setObject:[NSString stringWithFormat:@"TW=%ld(%2.f%%)", totalWin, ((double)totalWin/_totalMoney)*100.0] forKey:@"MaxBetting"];
    
}

-(void)simOneRoundGambling:(int)roundNo {
    int restMoney = _totalMoney;
    int winCount = 0, loseCount = 0;
    int minMoney = _totalMoney;
    int maxBetting = _eachBetting;
    NSMutableArray * history = [[NSMutableArray alloc] init];
    for (int t=0; t<_gamblingCount; t++) {
        BetType bet;
        float multiple;
        [self getTactics:history withBet:&bet andMultiple:&multiple];
        int d1,d2,d3;
        BetType result = [self throwThreeDice:&d1 andDice2:&d2 andDice3:&d3];
        int betMoney = _eachBetting * (int)multiple;
        if (betMoney > restMoney) {
            betMoney = restMoney;
            multiple = restMoney / _eachBetting;
        }
        if (restMoney-betMoney<minMoney) {
            minMoney = restMoney-betMoney;
        }
        if (betMoney > maxBetting) {
            maxBetting = betMoney;
        }
        BOOL isWin = NO;
        int winMoney = -betMoney;
        if (bet==result) {
            isWin = YES;
            winMoney = betMoney * (bet==BetTypeDraw?5:1);
            winCount++;
        } else {
            loseCount++;
        }
        restMoney+=winMoney;
        if (restMoney<=0) {
            restMoney = 0;
        }
        if (restMoney<minMoney) {
            minMoney = restMoney;
        }
        NSMutableDictionary * oneThrow = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:t+1], @"ThrowNo",
                                          [NSString stringWithFormat:@"%d %d %d", d1,d2,d3], @"ThrowDices",
                                          [self getBetTypeString:result], @"ThrowResult",
                                          [self getBetTypeString:bet], @"BetType",
                                          [NSNumber numberWithInt:betMoney], @"BetMoney",
                                          [NSNumber numberWithFloat:multiple], @"BetMultipe",
                                          isWin ? @"Yes" : @"No", @"IsWin",
                                          [NSNumber numberWithInt:winMoney], @"WinMoney",
                                          [NSNumber numberWithInt:restMoney], @"RestMoney",
                                          nil];
        [history addObject:oneThrow];
        if (restMoney<=0 || restMoney - _totalMoney >= _targetWin) {
            break;
        }
    }
    
    int winMoney = restMoney - _totalMoney;
    int maxLost = ((float)(_totalMoney - minMoney) / _totalMoney) * 100;
    
    NSMutableDictionary * roundResult = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:roundNo+1], @"RoundNo",
                                         [NSNumber numberWithInt:restMoney], @"Rest",
                                         [NSNumber numberWithInt:winMoney], @"WinMoney",
                                         [NSNumber numberWithInt:winCount], @"WinCount",
                                         [NSNumber numberWithInt:loseCount], @"LoseCount",
                                         [NSNumber numberWithInt:minMoney], @"MinMoney",
                                         [NSString stringWithFormat:@"%d (%d%%)", _totalMoney - minMoney, maxLost], @"MaxLost",
                                         [NSString stringWithFormat:@"%d (%d)", maxBetting, maxBetting / _eachBetting], @"MaxBetting",
                                         history, @"History",
                                         nil];
    [_result addObject:roundResult];
}

-(void)getTactics:(NSMutableArray*)history withBet:(BetType*)bet andMultiple:(float*)mul {
    NSDictionary * lastThrow = [history lastObject];
    BetType betType = BetTypeBig;
    float betMultiple = 1.0f;
    if (lastThrow!=nil) {
//        betType = [self getBetTypeByString:[lastThrow objectForKey:@"ThrowResult"]];
//        if (betType == BetTypeDraw) {
//            betType = [self getBetTypeRand];
//        }
        
        int lastWin = [[lastThrow objectForKey:@"WinMoney"] intValue];
        if (lastWin<0) {
            betMultiple = [[lastThrow objectForKey:@"BetMultipe"] floatValue] * _multiple;
        } else {
//            betMultiple = [[lastThrow objectForKey:@"BetMultipe"] intValue]  / 2;
//            if (betMultiple<=1) betMultiple = 1;
        }
        
//        int restMoney = [[lastThrow objectForKey:@"RestMoney"] intValue];
//        if (_dntMultiWinning && restMoney>=_totalMoney) {
//            betMultiple = 1;
//        }
        
        
        if (_hasMaxBetting && _eachBetting * betMultiple > _maxBetting) {
            betMultiple = _maxBetting / _eachBetting;
        }
    }
    *bet = betType;
    *mul = betMultiple;
}

-(int)throwOneDice {
    return arc4random() % 6 + 1;
}

-(NSString*)getBetTypeString:(BetType)type {
    if (type==BetTypeBig) return @"Big";
    if (type==BetTypeSmall) return @"Small";
    return @"Draw";
}

-(BetType)getBetTypeByString:(NSString*)type {
    if ([type isEqualToString:@"Big"]) return BetTypeBig;
    if ([type isEqualToString:@"Small"]) return BetTypeSmall;
    return BetTypeDraw;
}

-(BetType)getBetTypeDifferent:(BetType)type {
    if (type==BetTypeBig) return BetTypeSmall;
    return BetTypeBig;
}

-(BetType)getBetTypeRand {
    if (arc4random()%2==0) return BetTypeBig;
    return BetTypeSmall;
}


-(BetType)throwThreeDice:(int*)dd1 andDice2:(int*)dd2 andDice3:(int*)dd3 {
    int d1 = [self throwOneDice];
    int d2 = [self throwOneDice];
    int d3 = [self throwOneDice];
    *dd1 = d1;
    *dd2 = d2;
    *dd3 = d3;
    if (d1==d2 && d2==d3) return BetTypeDraw;
    if (d1+d2+d3<=10) return BetTypeSmall;
    return BetTypeBig;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView*)tv {
    if ([tv isEqualTo:_resultTable]) {
        return _result.count > 100 ? 100 : _result.count +1;
        //return 1;
    } else {
        return [[[_result objectAtIndex:_roundIndex] objectForKey:@"History"] count];
    }
}

- (id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)tc
            row:(NSInteger)rowIndex {
    NSString *strIdt = [tc identifier];
    if ([tv isEqualTo:_resultTable]) {
        if (rowIndex>0 && rowIndex-1<_result.count) {
            //NSLog(@"111");
            return [[_result objectAtIndex:rowIndex-1] objectForKey:strIdt];
        } else {
            return [_summary objectForKey:strIdt];
        }
    } else {
        //NSLog(@"222");
        if (rowIndex < [[[_result objectAtIndex:_roundIndex] objectForKey:@"History"] count]) {
            return [[[[_result objectAtIndex:_roundIndex] objectForKey:@"History"] objectAtIndex:rowIndex] objectForKey:strIdt];
        } else {
            return @"Blank";
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (_resultTable.selectedRow>=1 && _resultTable.selectedRow-1 < _result.count) {
        _roundIndex = (int)_resultTable.selectedRow - 1;
        [_detailTable setHidden:NO];
        [_lineChart setHidden:YES];
        [_detailTable reloadData];
    } else {
        [_detailTable setHidden:YES];
        [_lineChart setHidden:NO];
        [self drawLineChart];
    }
}

- (void)drawLineChart {
    
    [_detailTable setHidden:YES];
    [_lineChart setHidden:NO];

    PNLineChart * lineChart = (PNLineChart*)_lineChart;
    
//    [lineChart setXLabels:@[@"SEP 1",@"SEP 2",@"SEP 3",@"SEP 4",@"SEP 5"]];
    NSArray * sortedResult = [_result sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int m1 = [[obj1 objectForKey:@"Rest"] intValue];
        int m2 = [[obj2 objectForKey:@"Rest"] intValue];
        if (m1>m2) return NSOrderedDescending;
        if (m1<m2) return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    CGFloat maxValue = _totalMoney + _targetWin;
    
    
    // Line Chart No.1
    PNLineChartData *data01 = [PNLineChartData new];
    data01.color = PNFreshGreen;
    data01.itemCount = sortedResult.count;
    data01.getData = ^(NSUInteger index) {
        CGFloat yValue = [[sortedResult[index] objectForKey:@"Rest"] intValue] / maxValue;
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    
    // Line Chart No.2
//    NSArray * data02Array = @[[NSNumber numberWithInt:_totalMoney]];
    PNLineChartData *data02 = [PNLineChartData new];
    data02.color = PNTwitterColor;
    data02.itemCount = sortedResult.count;
    data02.getData = ^(NSUInteger index) {
        CGFloat yValue = _totalMoney  / maxValue;
//        if (index==0) yValue = 0;
//        if (index==sortedResult.count-1) yValue = (_totalMoney + _targetWin) / maxValue;
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    
    [lineChart setYValueMax:1.5];
    [lineChart setYValueMin:0];
    [lineChart setYFixedValueMax:1.5];
    [lineChart setYFixedValueMin:0];
    [lineChart setYLabelColor:[NSColor clearColor]];
    lineChart.chartData = @[data01, data02];
    [lineChart strokeChart];
}



















+ (void)runBlock:(void (^)(void))block inQueue:(dispatch_queue_t)queue afterDelay:(float)sec {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC));
    dispatch_after(popTime, queue, ^(void){
        block();
    });
}

+ (void)runBlock:(void (^)(void))block afterDelay:(float)sec {
    [self runBlock:block inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) afterDelay:sec];
}

+ (void)runBlockInBackground:(void(^)(void))block afterDelay:(float)sec {
    [self runBlock:block inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) afterDelay:sec];
}

+ (void)runBlockInMainQueue:(void(^)(void))block afterDelay:(float)sec {
    [self runBlock:block inQueue:dispatch_get_main_queue() afterDelay:sec];
}









@end
