#import "iAnnounceHelper.h"

static BOOL isEnabled;
static NSString *announcementTemplateString;
static float volumeLevel;

%hook SBCallAlertDisplay

- (void)updateLCDWithName:(id)fp8 label:(id)fp12 breakPoint:(unsigned int)fp16 {
	%log;
	
	if(![iAnnounceHelper isSilentMode] && isEnabled)
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
	if([iAnnounceHelper isSilentMode] || [iAnnounceHelper nameAnnounced] || !isEnabled)
	{
		%orig;
	}
}

%end

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
	}
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
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
		return;

	LoadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &PreferenceChangedCallback, CFSTR("com.hiren.iAnnouncePrefsChanged"), NULL, 0);

	[pool release];
}