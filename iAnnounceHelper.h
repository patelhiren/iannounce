//
//  iAnnounceHelper.h
//  iAnnounce
//
//  Created by Hiren Patel on 9/11/10.
//

#import <Foundation/Foundation.h>
#import "VoiceServices/VSSpeechSynthesizer.h"
#import <AudioToolBox/AudioToolBox.h>
#import "SpringBoard/SBCallAlertDisplay.h"
#import "SpringBoard/SBTelephonyManager.h"

@interface iAnnounceHelper : NSObject {

}

+(void) Say:(NSString*) text callAlertDisplay:(SBCallAlertDisplay*)callAlertDisp;
+(void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error;
+(BOOL) nameAnnounced;
+(BOOL) isSilentMode;

@end
