//
//  iAnnounceHelper.h
//  iAnnounce
//
//  Created by Hiren Patel on 9/11/10.
//

#import <Foundation/Foundation.h>
#import "VoiceServices/VSSpeechSynthesizer.h"
#import <AudioToolBox/AudioToolBox.h>
#import "SpringBoard/SBTelephonyManager.h"
#import "SpringBoard/SBMediaController.h"
#import "Celestial/AVSystemController.h"
#import "IncomingCall/MPIncomingPhoneCallController.h"
#import "IncomingCall/MPIncomingFaceTimeCallController.h"
#import "CaptainHook.h"


//#define IANNOUNCE_DEBUG 1 // Uncomment this line to enable debug logging.
#if !defined(IANNOUNCE_DEBUG)
    #define NSLog(...)
#endif

@interface iAnnounceHelper : NSObject {

}

+(void) Say:(NSString*) text callAlertDisplay:(id)callAlertDisp announceVolumeLevel:(float) announceVolumeLevel usingLanguageCode:(NSString *) languageCode atSpeechRate:(float) rate atSpeechPitch:(float) pitch;
+(void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error;
+(BOOL) nameAnnounced;
+(BOOL) isSilentMode: (BOOL) headphonesOnlyAnnounce;
+(void) stopSpeaking;
+(void) reloadSettings;
@end

