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

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@implementation iAnnounceHelper

+(void) Say:(NSString*) text callAlertDisplay:(id)callAlertDisp announceVolumeLevel:(float) announceVolumeLevel{
	
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


+(BOOL)nameAnnounced {
	return _doneSpeaking;
}


+(BOOL) isSilentMode: (BOOL) headphonesOnlyAnnounce {

@try
{
	AudioSessionInitialize(NULL, NULL, NULL, NULL);

	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
		CFDictionaryRef cfDictRef = nil;
		UInt32 dataSize = sizeof(cfDictRef);
		AudioSessionGetProperty(kAudioSessionProperty_AudioRouteDescription, &dataSize, &cfDictRef);
		NSDictionary *nsDict = (NSDictionary *)cfDictRef;
		if(nsDict != nil && nsDict.count > 0)
		{
			NSLog(@"AudioSessionGetProperty val = %@", nsDict);
			NSDictionary *routeDetailedDescriptionOutputsDict = [nsDict valueForKey:@"RouteDetailedDescription_Outputs"];
			if(routeDetailedDescriptionOutputsDict != nil && routeDetailedDescriptionOutputsDict.count > 0)
			{
				NSDictionary *firstOutput = (NSDictionary *)[[nsDict valueForKey:@"RouteDetailedDescription_Outputs"] objectAtIndex:0];
				NSString *portType = (NSString *)[firstOutput valueForKey:@"RouteDetailedDescription_PortType"];
				NSLog(@"iAnnounce: First sound output port type is: %@", portType);
				
				if( headphonesOnlyAnnounce ) {
					if ([portType isEqualToString: @"Headphones"] )
					{
						return NO;
					}
					return YES;
				}
				else {
					if([portType isEqualToString: @"Speaker"]) {
						SBMediaController* mediaController = [objc_getClass("SBMediaController") sharedInstance];
						if (mediaController != nil)  {
							NSLog(@"iAnnounce: Got SBMediaController.");
							NSLog(@"iAnnounce: SBMediaController isRingerMuted=%d.", [mediaController isRingerMuted]);
							return [mediaController isRingerMuted];
						}
					}
				}
			}
			else {
				NSLog(@"iAnnounce: No sound output port available. Must be iOS 6. Will treat as silent mode.");
				return YES;
			}
		}
	}
	else {	
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
