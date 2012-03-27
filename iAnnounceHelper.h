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
#import "CaptainHook.h"

@interface iAnnounceHelper : NSObject {

}

+(void) Say:(NSString*) text callAlertDisplay:(id)callAlertDisp announceVolumeLevel:(float) announceVolumeLevel;
+(void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error;
+(BOOL) nameAnnounced;
+(BOOL) isSilentMode: (BOOL) headphonesOnlyAnnounce;

@end
