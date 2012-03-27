#import "iAnnounceHelper.h"

static BOOL isEnabled;
static NSString *announcementTemplateString;
static float volumeLevel;
static BOOL headphonesOnly;

%hook SBCallAlertDisplay

- (void)updateLCDWithName:(id)fp8 label:(id)fp12 breakPoint:(unsigned int)fp16 {
	%log;
	
	if(![iAnnounceHelper isSilentMode:headphonesOnly] && isEnabled)
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
		
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel];
	}
	
	%orig;
}

- (void)ringOrVibrate
{
	%log;
	if([iAnnounceHelper isSilentMode:headphonesOnly] || [iAnnounceHelper nameAnnounced] || !isEnabled)
	{
		%orig;
	}
}

%end

CHDeclareClass(MPIncomingPhoneCallController);

CHOptimizedMethod(3, self, void, MPIncomingPhoneCallController, updateLCDWithName, NSString *, name, label, NSString *, aLabel, breakPoint, unsigned, aBreakPoint) {
	NSLog(@"iAnnounce: Incomming call from %@. Phone type %@.", name, aLabel);
	if(![iAnnounceHelper isSilentMode:headphonesOnly] && isEnabled)
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
		
		[iAnnounceHelper Say:callString callAlertDisplay:self announceVolumeLevel:volumeLevel];
	}
    CHSuper(3, MPIncomingPhoneCallController, updateLCDWithName, name, label, aLabel, breakPoint, aBreakPoint);
}

CHOptimizedMethod(0, self, void, MPIncomingPhoneCallController, ringOrVibrate) {
	NSLog(@"iAnnounce: Hooked ringOrVibrate");
	if([iAnnounceHelper isSilentMode:headphonesOnly] || [iAnnounceHelper nameAnnounced] || !isEnabled)
	{
		CHSuper(0, MPIncomingPhoneCallController, ringOrVibrate);
	}
}

CHDeclareClass(SBPluginManager);

CHOptimizedMethod(1, self, Class, SBPluginManager, loadPluginBundle, NSBundle *, bundle) {
    id ret = CHSuper(1, SBPluginManager, loadPluginBundle, bundle);

    if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilephone.incomingcall"] && [bundle isLoaded]) {
    	NSLog(@"iAnnounce: SBPluginManager loaded com.apple.mobilephone.incomingcall");
        CHLoadLateClass(MPIncomingPhoneCallController);
        CHHook(3, MPIncomingPhoneCallController, updateLCDWithName, label, breakPoint);
        CHHook(0, MPIncomingPhoneCallController, ringOrVibrate);
    }

    return ret;
}

CHConstructor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    CHLoadLateClass(SBPluginManager);
    CHHook(1, SBPluginManager, loadPluginBundle);

    [pool drain];
}

static void LoadSettings()
{
	NSDictionary *settings([NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.hiren.iAnnounce.plist", NSHomeDirectory()]]);
	if (settings != nil)
	{
		NSNumber *enabled = [settings objectForKey:@"isEnabled"];
        isEnabled = enabled == nil ? true : [enabled boolValue];
		
		if(announcementTemplateString != nil)
			[announcementTemplateString release];
		announcementTemplateString = [settings objectForKey:@"callString"];
		if(announcementTemplateString == nil || [announcementTemplateString length] == 0)
		{
			announcementTemplateString = @"Attention. Incoming call from %%CALLERID%%, %%PHONETYPE%%";
		}
		[announcementTemplateString retain];
		
		NSNumber *announceVolumeLevel = [settings objectForKey:@"iAnnounce-Volume"];
        volumeLevel = announceVolumeLevel == nil ? 1.0 : [announceVolumeLevel floatValue];
        
        NSNumber *_headphonesOnly = [settings objectForKey:@"headphonesOnly"];
        headphonesOnly = _headphonesOnly == nil ? true : [_headphonesOnly boolValue];
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