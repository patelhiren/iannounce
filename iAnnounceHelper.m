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

@implementation iAnnounceHelper

+(void) Say:(NSString*) text callAlertDisplay:(SBCallAlertDisplay*)callAlertDisp {
	_doneSpeaking = NO;
	callAlert = callAlertDisp;
	[callAlert retain];
	if (v == nil)
	{
		v= [[VSSpeechSynthesizer alloc] init]; 
		[v setDelegate:[iAnnounceHelper class]];
	}
	[v startSpeakingString:text];
}


+ (void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error  { 
	NSLog(@"iAnnounce: Done announcing Caller.");
	_doneSpeaking = YES;

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
