//
//  FDMessageController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDInputToolbarView.h"

@interface FDMessageController : UIViewController <FDInputToolbarViewDelegate, FDGrowingTextViewDelegate>

-(instancetype)initWithConversation:(NSString *)conversation;

@end