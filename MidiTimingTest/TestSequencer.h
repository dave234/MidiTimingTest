//
//  TestSequencer.h
//  MidiTimingTest
//
//  Created by David O'Neill on 8/15/17.
//  Copyright © 2017 O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface TestSequencer : NSObject
-(void)setRenderNotify:(AudioUnit)audioUnit;
-(void)start;
@end
