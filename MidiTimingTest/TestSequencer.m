//
//  TestSequencer.m
//  MidiTimingTest
//
//  Created by David O'Neill on 8/15/17.
//  Copyright © 2017 O'Neill. All rights reserved.
//

#import "TestSequencer.h"

#define NOTEON 144
#define NOTEOFF 128

typedef AudioStreamBasicDescription ASBD;

@implementation TestSequencer {
    AudioTimeStamp lastRenderTime;
    ASBD asbd;
    double starts[8];
    double stops[8];
    AudioUnit _sampler;
    int framesPerRender;
}
-(void)setRenderNotify:(AudioUnit)sampler {

    _sampler = sampler;

    OSStatus status = AudioUnitAddRenderNotify(sampler, renderCallback, (__bridge void *)self);
    if (status)printf("%d %d\n",status,__LINE__);

    UInt32 propSize = sizeof(ASBD);
    status = AudioUnitGetProperty(sampler, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, &propSize);
    printf("samplerate %f\n",asbd.mSampleRate);
    _sampler = sampler;
}
-(void)start{

    double startSample = lastRenderTime.mSampleTime + framesPerRender;
    double interval = 0.25 * asbd.mSampleRate;
    double duration = 0.1 * asbd.mSampleRate;
    for (int i = 0; i < 8; i++){
        starts[i] = startSample + interval * i;
        stops[i] = starts[i] + duration;
    }
}
static OSStatus renderCallback(void                         * inRefCon,
                               AudioUnitRenderActionFlags   * ioActionFlags,
                               const AudioTimeStamp         * inTimeStamp,
                               UInt32                       inBusNumber,
                               UInt32                       inNumberFrames,
                               AudioBufferList              * ioData) {

    if (!(*ioActionFlags & kAudioUnitRenderAction_PreRender)) {
        return noErr;
    }

    TestSequencer *self = (__bridge __unsafe_unretained TestSequencer *)inRefCon;
    self->lastRenderTime = *inTimeStamp;
    self->framesPerRender = inNumberFrames;

    double startSample = inTimeStamp->mSampleTime;
    double endSample = startSample + inNumberFrames;

    for (int i = 0; i < 8; i++){
        if (self->starts[i] >= startSample && self->starts[i] < endSample) {

            UInt32 sampleOffsetFromRenderStart = self->starts[i] - startSample;  //This is what's missing from the AVFoundation implementation!
            MusicDeviceMIDIEvent(self->_sampler,NOTEON,64,127,sampleOffsetFromRenderStart);
        }
        if (self->stops[i] >= startSample && self->stops[i] < endSample) {

            UInt32 sampleOffsetFromRenderStart = self->stops[i] - startSample;  //This is what's missing from the AVFoundation implementation!
            MusicDeviceMIDIEvent(self->_sampler,NOTEOFF,64, 0,sampleOffsetFromRenderStart);
        }
    }

    return noErr;
}
@end


