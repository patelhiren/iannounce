//
//  iAnnounceHelper.m
//  iAnnounce
//
//  Created by Hiren Patel on 9/11/10.
//

#import "iAnnounceHelper.h"

static BOOL _doneSpeaking;
static 	VSSpeechSynthesizer *v;
static id callAlert;
static Class $SBTelephonyManager;
static float currentVolume;
static BOOL volumeSet;
static BOOL isHeadphonesConnected;
static BOOL _isSpeaking;

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@implementation iAnnounceHelper

+(void) reloadSettings {
	[v release];
	v = nil;
}

+(void) Say:(NSString*) text callAlertDisplay:(id)callAlertDisp announceVolumeLevel:(float) announceVolumeLevel usingLanguageCode:(NSString *) languageCode atSpeechRate:(float) rate atSpeechPitch:(float) pitch {
	if(_isSpeaking) {
		return;
	}
	_doneSpeaking = NO;
	_isSpeaking = YES;
	callAlert = callAlertDisp;
	[callAlert retain];
	
	if (!volumeSet) {
		NSString *portType = [[AVSystemController sharedAVSystemController] routeForCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: routeForCategory = %@", portType);
		if([portType isEqualToString: @"Speaker"]) {
			if([[AVSystemController sharedAVSystemController] getVolume: &currentVolume forCategory:@"Audio/Video"]) {
				NSLog(@"iAnnounce: Current iPod Volume = %f", currentVolume);
				if([[AVSystemController sharedAVSystemController] setVolumeTo:announceVolumeLevel forCategory:@"Audio/Video"]) {
					NSLog(@"iAnnounce: Current iPod Volume set to %f for Announcing name.", announceVolumeLevel);
					volumeSet = YES;
				}
			}
		}
	}
	
	if (v == nil)
	{
		v = [[VSSpeechSynthesizer alloc] init]; 
		[v retain];
		[v setDelegate:[iAnnounceHelper class]];
		
		[v setRate: rate];
		[v setPitch:pitch];
	}
	
	if(languageCode != nil && languageCode.length > 0) {
		[v startSpeakingString:text withLanguageCode:languageCode];
	}
	else {
		[v startSpeakingString:text];
	}
}

+ (void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error  { 
	NSLog(@"iAnnounce: Done announcing Caller.");
	_doneSpeaking = YES;
	_isSpeaking = NO;
	
	if(volumeSet) {
		[[AVSystemController sharedAVSystemController] setVolumeTo:currentVolume forCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: Resetting Current iPod Volume = %f", currentVolume);
		volumeSet = NO;
	}
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
            /*if ([callAlert isKindOfClass:[objc_getClass("MPIncomingFaceTimeCallController") class]]) {
                MPIncomingFaceTimeCallController *callController = (MPIncomingFaceTimeCallController*) callAlert;
                [callController ringOrVibrate];
                
            }
            else if ([callAlert isKindOfClass:[objc_getClass("MPIncomingPhoneCallController") class]]) {
                MPIncomingFaceTimeCallController *callController = (MPIncomingFaceTimeCallController*) callAlert;
                [callController ringOrVibrate];
            }*/
            [callAlert ringOrVibrate];
		}else {
			NSLog(@"iAnnounce: Another call already in progress. Will not ringOrVibrage.");
		}
	}
	[callAlert release];
	callAlert = nil;
}

+(void) stopSpeaking {
	NSLog(@"iAnnounce: Stopping announcing caller.");
	_doneSpeaking = YES;
	_isSpeaking = NO;
	if(v != nil) {
		[v stopSpeakingAtNextBoundary:0];
	}
	if(volumeSet) {
		[[AVSystemController sharedAVSystemController] setVolumeTo:currentVolume forCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: Resetting Current iPod Volume = %f", currentVolume);
		volumeSet = NO;
	}
	[callAlert release];
	callAlert = nil;
}

+(BOOL)nameAnnounced {
	return _doneSpeaking;
}

+(BOOL) isSilentMode: (BOOL) headphonesOnlyAnnounce {

@try
{	
	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
	
		SBMediaController* mediaController = [objc_getClass("SBMediaController") sharedInstance];
		if (mediaController != nil)  {
			NSLog(@"iAnnounce: Got SBMediaController.");
			NSLog(@"iAnnounce: SBMediaController isRingerMuted=%d.", [mediaController isRingerMuted]);
		}
		
		NSString *portType = [[AVSystemController sharedAVSystemController] routeForCategory:@"Audio/Video"];
		NSLog(@"iAnnounce: routeForCategory = %@", portType);
		if([portType isEqualToString: @"Headphone"]) {
			NSLog(@"iAnnounce: Headphones only announce and Headphones are connected.");
			isHeadphonesConnected = YES;
		}
		
		if( headphonesOnlyAnnounce && !isHeadphonesConnected) {
			return YES;
		}
		else {
			if([portType isEqualToString: @"Speaker"] && mediaController != nil) {
				return [mediaController isRingerMuted];
			}
		}
	}
	else {	
		AudioSessionInitialize(NULL, NULL, NULL, NULL);
		CFStringRef state;
		UInt32 propertySize = sizeof(CFStringRef);
		AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
		if(CFStringGetLength(state) == 0)
		{
			return YES;
		}
		return NO;
	}
	
	}@catch(NSException * e)
	{
		NSLog(@"iAnnounce: Exception while detecting Silent Mode. Will Assume silent mode. %@", e);
		return YES;
	}
	return NO;
}

@end
