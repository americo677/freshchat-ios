//
//  FDParticipant.h
//  HotlineSDK
//
//  Created by user on 10/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface FDParticipant : NSManagedObject

@property (nonatomic, retain) NSString *alias;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *profilePicURL;


@end
