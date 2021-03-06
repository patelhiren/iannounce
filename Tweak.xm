#import "iAnnounceHelper.h"

static BOOL isEnabled;
static NSString *announcementTemplateString;
static NSString *announcementFacetimeTemplateString;
static float volumeLevel;
static BOOL headphonesOnly;
static NSString *languageCode;
static float speechRate;
static float speechPitch;

%hook SBCallAlertDisplay

- (void)updateLCDWithName:(id)fp8 label:(id)fp12 breakPoint:(unsigned int)fp16 {
	%log;
	
	if(isEnabled && ![iAnnounceHelper isSilentMode:headphonesOnly])
	{
		NSString* callString;
		NSString *callID = (NSString *)fp8;
		if(fp12 != nil)
		{
			NSString *phoneType = (NSString *)fp12;
			callString = [announcementTemplateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:phoneType];
		}
		else
		{
			callString = [announcementTemplateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:@""];
		}
		
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel usingLanguageCode:languageCode atSpeechRate:speechRate atSpeechPitch:speechPitch];
	}
	
	%orig;
}

- (void)ringOrVibrate
{
	%log;
	if(!isEnabled || [iAnnounceHelper nameAnnounced] || [iAnnounceHelper isSilentMode:headphonesOnly])
	{
		%orig;
	}
}

%end

CHDeclareClass(MPIncomingFaceTimeCallController);

CHOptimizedMethod(2, self, void, MPIncomingFaceTimeCallController, updateTopBarWithName, NSString *, name, image, id, fp12) {
	NSLog(@"iAnnounce: Facetime call from %@. Phone type %@.", name);
	if(isEnabled && ![iAnnounceHelper isSilentMode:headphonesOnly])
	{
		NSString* callString;
		NSString *callID = (NSString *)name;
		
		callString = [announcementFacetimeTemplateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
		callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:@""];
		
		NSLog(@"iAnnounce: Announcing Facetime call as %@", callString);
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel usingLanguageCode:languageCode atSpeechRate:speechRate atSpeechPitch:speechPitch];
	}
    CHSuper(2, MPIncomingFaceTimeCallController, updateTopBarWithName, name, image, fp12);
}

CHOptimizedMethod(0, self, void, MPIncomingFaceTimeCallController, ringOrVibrate) {
	NSLog(@"iAnnounce: Hooked [MPIncomingFaceTimeCallController ringOrVibrate]");
	if(!isEnabled || [iAnnounceHelper nameAnnounced] || [iAnnounceHelper isSilentMode:headphonesOnly])
	{
		CHSuper(0, MPIncomingFaceTimeCallController, ringOrVibrate);
	}
}

CHOptimizedMethod(0, self, void, MPIncomingFaceTimeCallController, stopRingingOrVibrating) {
	if(isEnabled) {
		NSLog(@"iAnnounce: Hooked stopRingingOrVibrating");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, MPIncomingFaceTimeCallController, stopRingingOrVibrating);
}

CHDeclareClass(MPIncomingPhoneCallController);

CHOptimizedMethod(3, self, void, MPIncomingPhoneCallController, updateLCDWithName, NSString *, name, label, NSString *, aLabel, breakPoint, unsigned, aBreakPoint) {
	NSLog(@"iAnnounce: Incoming call from %@. Phone type %@.", name, aLabel);
	if(isEnabled && ![iAnnounceHelper isSilentMode:headphonesOnly])
	{
		NSString* callString;
		NSString *callID = (NSString *)name;
		if(aLabel != nil)
		{
			NSString *phoneType = (NSString *)aLabel;
			callString = [announcementTemplateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:phoneType];
		}
		else
		{
			callString = [announcementTemplateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:@""];
		}
		NSLog(@"iAnnounce: Announcing Incoming call as %@", callString);
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel usingLanguageCode:languageCode atSpeechRate:speechRate atSpeechPitch:speechPitch];
	}
    CHSuper(3, MPIncomingPhoneCallController, updateLCDWithName, name, label, aLabel, breakPoint, aBreakPoint);
}

CHOptimizedMethod(0, self, void, MPIncomingPhoneCallController, ringOrVibrate) {
	NSLog(@"iAnnounce: Hooked ringOrVibrate");
	if(!isEnabled || [iAnnounceHelper nameAnnounced] || [iAnnounceHelper isSilentMode:headphonesOnly])
	{
		CHSuper(0, MPIncomingPhoneCallController, ringOrVibrate);
	}
}

CHOptimizedMethod(0, self, void, MPIncomingPhoneCallController, stopRingingOrVibrating) {
	if(isEnabled) {
		NSLog(@"iAnnounce: Hooked stopRingingOrVibrating");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, MPIncomingPhoneCallController, stopRingingOrVibrating);
}

CHDeclareClass(SBPluginManager);

CHOptimizedMethod(1, self, Class, SBPluginManager, loadPluginBundle, NSBundle *, bundle) {
    id ret = CHSuper(1, SBPluginManager, loadPluginBundle, bundle);

    if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilephone.incomingcall"] && [bundle isLoaded]) {
    	NSLog(@"iAnnounce: SBPluginManager loaded com.apple.mobilephone.incomingcall");
        CHLoadLateClass(MPIncomingPhoneCallController);
        CHHook(3, MPIncomingPhoneCallController, updateLCDWithName, label, breakPoint);
        CHHook(0, MPIncomingPhoneCallController, ringOrVibrate);
        CHHook(0, MPIncomingPhoneCallController, stopRingingOrVibrating);
        
        CHLoadLateClass(MPIncomingFaceTimeCallController);
        CHHook(2, MPIncomingFaceTimeCallController, updateTopBarWithName, image);
        CHHook(0, MPIncomingFaceTimeCallController, ringOrVibrate);
        CHHook(0, MPIncomingFaceTimeCallController, stopRingingOrVibrating);
    }

    return ret;
}

CHDeclareClass(CallBarController);

/*CHOptimizedMethod(1, self, int, CallBarController, ABUIDForIncomingCall, id, incomingCall) {
	int retVal = CHSuper(1, CallBarController, ABUIDForIncomingCall, incomingCall);
	if(isEnabled) {
		NSLog(@"iAnnounce : Hooked CallBarController ABUIDForIncomingCall. incomingCall: %@, retVal = %d", incomingCall, retVal);
		[iAnnounceHelper setNameAnnounced:NO];
	}
	return retVal;
}*/

CHOptimizedMethod(4, self, void, CallBarController, showCallBarWithCall, id, call, callType, unsigned, type, fromID, id, anId, conferenceID, id, anId4) {	
	CHSuper(4, CallBarController, showCallBarWithCall, call, callType, type, fromID, anId, conferenceID, anId4);
		
	if(isEnabled && (type == 1 || type == 2) && ![iAnnounceHelper isSilentMode:headphonesOnly])
	{
		NSString* callString;
		NSString *callID = [self contactNameForNumber:[self callingNumber]];
		if(callID == nil || ([callID length] <= 0)) {
			callID = [self callingNumber];
		}
		NSLog(@"iAnnounce: Hooked CallBarController showCallBarWithCall. call:%@, callType: %d, type: %@, conferenceID:%@, callingNumber:%@, contactNameForNumber: %@", call, type, anId, anId4, [self callingNumber], callID);
		NSString *aLabel = nil;

		if(callID == nil || ([callID length] <= 0)) {
			NSLog(@"iAnnounce: CallBarController showCallBarWithCall. Replacing missing CallerID with 'BLOCKED'.");
			callID = @"BLOCKED";
		}
		
		NSString *templateString = announcementFacetimeTemplateString;
		if(type != 2) {
			templateString = announcementTemplateString;
			NSLog(@"iAnnounce: CallBarController [self infoLabel] = %@", [self infoLabel]);
			aLabel = [[self infoLabel] text];
		}
		
		if(aLabel != nil)
		{
			NSString *phoneType = (NSString *)aLabel;
			callString = [templateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:phoneType];
		}
		else
		{
			callString = [templateString stringByReplacingOccurrencesOfString:@"%%CALLERID%%" withString:callID];
			callString = [callString stringByReplacingOccurrencesOfString:@"%%PHONETYPE%%" withString:@""];
		}
		NSLog(@"iAnnounce: Announcing Incoming call as %@", callString);
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel usingLanguageCode:languageCode atSpeechRate:speechRate atSpeechPitch:speechPitch];
	}
}

CHOptimizedMethod(0, self, void, CallBarController, playRingtoneOrVibrate) {
	NSLog(@"iAnnounce: Hooked CallBarController playRingtoneOrVibrate. [iAnnounceHelper nameAnnounced] = %d", [iAnnounceHelper nameAnnounced]);
	if(!isEnabled || [iAnnounceHelper nameAnnounced] || [iAnnounceHelper isSilentMode:headphonesOnly])
	{
		CHSuper(0, CallBarController, playRingtoneOrVibrate);
	}
}

CHOptimizedMethod(0, self, void, CallBarController, answerCallWithInPlaceOptions) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController answerCallWithInPlaceOptions");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, answerCallWithInPlaceOptions);	
}

CHOptimizedMethod(0, self, void, CallBarController, answerCurrentCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController answerCurrentCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, answerCurrentCall);	
}

CHOptimizedMethod(0, self, void, CallBarController, declineCurrentCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController declineCurrentCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, declineCurrentCall);	
}

CHOptimizedMethod(0, self, void, CallBarController, animateToSilentState) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController animateToSilentState");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, animateToSilentState);	
}

CHOptimizedMethod(0, self, void, CallBarController, answerCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController answerCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, answerCall);	
}

CHOptimizedMethod(0, self, void, CallBarController, declineCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController declineCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, declineCall);	
}

CHOptimizedMethod(0, self, void, CallBarController, answerFacetimeCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController answerFacetimeCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, answerFacetimeCall);	
}

CHOptimizedMethod(0, self, void, CallBarController, declineFacetimeCall) {
	if(isEnabled)
	{
		NSLog(@"iAnnounce: Hooked CallBarController declineFacetimeCall");
		[iAnnounceHelper stopSpeaking];
	}
	CHSuper(0, CallBarController, declineFacetimeCall);	
}

CHConstructor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    CHLoadLateClass(SBPluginManager);
    CHHook(1, SBPluginManager, loadPluginBundle);

	CHLoadLateClass(CallBarController);
	//CHHook(1, CallBarController, ABUIDForIncomingCall);
	CHHook(4, CallBarController, showCallBarWithCall, callType, fromID, conferenceID);
	CHHook(0, CallBarController, playRingtoneOrVibrate);
	CHHook(0, CallBarController, answerCallWithInPlaceOptions);
	CHHook(0, CallBarController, answerCurrentCall);
	CHHook(0, CallBarController, declineCurrentCall);
	CHHook(0, CallBarController, animateToSilentState);
	CHHook(0, CallBarController, answerCall);
	CHHook(0, CallBarController, declineCall);	
	CHHook(0, CallBarController, answerFacetimeCall);
	CHHook(0, CallBarController, declineFacetimeCall);
	
    [pool drain];
}

static void LoadSettings()
{
	[announcementTemplateString release];
	[languageCode release];
	[announcementFacetimeTemplateString release];
	
	[iAnnounceHelper reloadSettings];
	
	NSDictionary *settings([NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.hiren.iAnnounce.plist", NSHomeDirectory()]]);
	if (settings != nil)
	{
		NSNumber *enabled = [settings objectForKey:@"isEnabled"];
        isEnabled = enabled == nil ? true : [enabled boolValue];
				
		announcementTemplateString = [settings objectForKey:@"callString"];
		if(announcementTemplateString == nil || [announcementTemplateString length] == 0)
		{
			announcementTemplateString = @"Attention. Call from %%CALLERID%%, %%PHONETYPE%%";
		}
		[announcementTemplateString retain];
			
		announcementFacetimeTemplateString = [settings objectForKey:@"facetimeString"];
		if(announcementFacetimeTemplateString == nil || [announcementFacetimeTemplateString length] == 0)
		{
			announcementFacetimeTemplateString = @"Attention. FaceTime from %%CALLERID%%";
		}
		[announcementFacetimeTemplateString retain];
		
		NSNumber *announceVolumeLevel = [settings objectForKey:@"iAnnounce-Volume"];
        volumeLevel = announceVolumeLevel == nil ? 1.0 : [announceVolumeLevel floatValue];
        
        NSNumber *_headphonesOnly = [settings objectForKey:@"headphonesOnly"];
        headphonesOnly = _headphonesOnly == nil ? false : [_headphonesOnly boolValue];
        
        languageCode = [settings objectForKey:@"languageCodeString"];
        if(languageCode != nil && languageCode.length > 0) {
        	[languageCode retain];
        	NSSet *availableLanguageCodes = [VSSpeechSynthesizer availableLanguageCodes];
        	NSLog(@"iAnnounce: Available Language Codes: %@", availableLanguageCodes);
        	BOOL languageCodeFound = [availableLanguageCodes containsObject:languageCode];
        	if(!languageCodeFound) {
        		NSLog(@"iAnnounce: Language Code %@ is not a valid language code. Will use system settings.", languageCode);
        		[languageCode release];
        		languageCode = nil;
        	}
        }
        else {
        	languageCode = nil;
        }
        
        NSNumber *speechRateLevel = [settings objectForKey:@"iAnnounce-Rate"];
        speechRate = speechRateLevel == nil ? 1.0 : [speechRateLevel floatValue];
        
        NSNumber *speechPitchLevel = [settings objectForKey:@"iAnnounce-Pitch"];
        speechPitch = speechPitchLevel == nil ? 0.5 : [speechPitchLevel floatValue];
	}
	else
	{
		isEnabled = true;
		
		announcementTemplateString = [settings objectForKey:@"callString"];
		announcementTemplateString = @"Attention. Call from %%CALLERID%%, %%PHONETYPE%%";
		[announcementTemplateString retain];
		
		announcementFacetimeTemplateString = @"Attention. FaceTime from %%CALLERID%%";
		[announcementFacetimeTemplateString retain];
		
		volumeLevel = 1.0;
        headphonesOnly = false;
        languageCode = nil;
        speechRate = 1.0;
        speechPitch = 0.5;
	}
	NSLog(@"iAnnounce: Enabled = %d", isEnabled);
}

static void PreferenceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"iAnnounce: Preferences changed. Reloading.");
	LoadSettings();
}

__attribute__((constructor)) static void iAnnounce_init()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// SpringBoard only.
	//if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
	//	return;

	LoadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &PreferenceChangedCallback, CFSTR("com.hiren.iAnnouncePrefsChanged"), NULL, 0);

	[pool release];
}