//
//  iAnnounceHelper.m
//  iAnnounce
//
//  Created by Hiren Patel on 9/11/10.
//

#import "iAnnounceHelper.h"

static BOOL _doneSpeaking;
static 	VSSpeechSynthesizer *v;
static SBCallAlertDisplay *callAlert;
static Class $SBTelephonyManager;
static float currentVolume;
static BOOL volumeSet;

@implementation iAnnounceHelper

+(void) Say:(NSString*) text callAlertDisplay:(SBCallAlertDisplay*)callAlertDisp announceVolumeLevel:(float) announceVolumeLevel{
	
	_doneSpeaking = NO;
	callAlert = callAlertDisp;
	[callAlert retain];
	if (v == nil)
	{
		v= [[VSSpeechSynthesizer alloc] init]; 
		[v setDelegate:[iAnnounceHelper class]];
	}
	if (!volumeSet) {
		[[AVSystemController sharedAVSystemController] getVolume: &currentVolume forCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: Current iPod Volume = %f", currentVolume);
		[[AVSystemController sharedAVSystemController] setVolumeTo:announceVolumeLevel forCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: Current iPod Volume set to max for Announcing name.");
		volumeSet = YES;
	}
	[v startSpeakingString:text];
}


+ (void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error  { 
	NSLog(@"iAnnounce: Done announcing Caller.");
	_doneSpeaking = YES;

	[[AVSystemController sharedAVSystemController] setVolumeTo:currentVolume forCategory:@"Audio/Video"];
	NSLog(@"iAnnounce: Resetting Current iPod Volume = %f", currentVolume);
	volumeSet = NO;
	if(callAlert != nil && [callAlert retainCount] > 0)
	{
		BOOL shouldRing = YES;
		if ($SBTelephonyManager == nil) {
			$SBTelephonyManager = objc_getClass("SBTelephonyManager");
		}
		
		SBTelephonyManager *mgr = [$SBTelephonyManager sharedTelephonyManager];
		if (mgr) {
			if (mgr.inCall) {
				shouldRing = NO;
			}
		}
		if (shouldRing) {
			NSLog(@"iAnnounce: Now calling ringOrVibrate. SBCallAlertDisplay retainCount = %d.", [callAlert retainCount]);
			[callAlert ringOrVibrate];
		}else {
			NSLog(@"iAnnounce: Another call already in progress. Will not ringOrVibrage.");
		}
	}
	[callAlert release];
	callAlert = nil;
}


+(BOOL)nameAnnounced {
	return _doneSpeaking;
}


+(BOOL) isSilentMode {
	CFStringRef state;
	UInt32 propertySize = sizeof(CFStringRef);
	AudioSessionInitialize(NULL, NULL, NULL, NULL);
	AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
	if(CFStringGetLength(state) == 0)
	{
		return YES;
	}
	return NO;
}

@end
