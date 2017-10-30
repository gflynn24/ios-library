/* Copyright 2017 Urban Airship and Contributors */

#import "UAScheduleInfo+Internal.h"
#import "UAUtils.h"

NSUInteger const UAScheduleInfoMaxTriggers = 10;

NSString *const UAScheduleInfoPriorityKey = @"priority";
NSString *const UAScheduleInfoLimitKey = @"limit";
NSString *const UAScheduleInfoGroupKey = @"group";
NSString *const UAScheduleInfoEndKey = @"end";
NSString *const UAScheduleInfoStartKey = @"start";
NSString *const UAScheduleInfoTriggersKey = @"triggers";
NSString *const UAScheduleInfoDelayKey = @"delay";

NSString * const UAScheduleInfoErrorDomain = @"com.urbanairship.schedule_info";


@implementation UAScheduleInfoBuilder

- (BOOL)applyFromJson:(id)json error:(NSError * _Nullable *)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return NO;
    }

    // Priority
    id priority = json[UAScheduleInfoPriorityKey];
    if (priority && ![priority isKindOfClass:[NSNumber class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Priority must be defined and be a number. Invalid value: %@", priority];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return NO;
    }

    // Limit
    id limit = json[UAScheduleInfoLimitKey];
    if (limit && ![limit isKindOfClass:[NSNumber class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Limit must be defined and be a number. Invalid value: %@", limit];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return NO;
    }

    // Start
    NSDate *start;
    if (json[UAScheduleInfoStartKey]) {
        if (![json[UAScheduleInfoStartKey] isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Start must be ISO 8601 timestamp. Invalid value: %@", start];
                *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                              code:UAScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return NO;
        }

        start = [UAUtils parseISO8601DateFromString:json[UAScheduleInfoStartKey]];
    }

    // End
    NSDate *end;
    if (json[UAScheduleInfoEndKey]) {
        if (![json[UAScheduleInfoEndKey] isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"End must be ISO 8601 timestamp. Invalid value: %@", end];
                *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                              code:UAScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return NO;
        }

        end = [UAUtils parseISO8601DateFromString:json[UAScheduleInfoEndKey]];
    }

    // Group
    id group = json[UAScheduleInfoGroupKey];
    if (group && ![group isKindOfClass:[NSString class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Group must be a string. Invalid value: %@", group];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return NO;
    }

    // Triggers
    NSMutableArray *triggers = [NSMutableArray array];
    id triggersJSONArray = json[UAScheduleInfoTriggersKey];
    if (!triggersJSONArray || ![triggersJSONArray isKindOfClass:[NSArray class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Schedule must contain an array of triggers. Invalid value %@", triggersJSONArray];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return NO;
    }

    for (id triggerJSON in triggersJSONArray) {
        UAScheduleTrigger *trigger = [UAScheduleTrigger triggerWithJSON:triggerJSON error:error];
        if (!trigger) {
            return NO;
        }

        [triggers addObject:trigger];
    }

    if (!triggers.count) {
        if (error) {
            NSString *msg = @"Schedule must contain at least 1 trigger.";
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }
        return NO;
    }

    // Delay
    UAScheduleDelay *delay = nil;
    if (json[UAScheduleInfoDelayKey]) {
        if (![json[UAScheduleInfoDelayKey] isKindOfClass:[NSDictionary class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Delay payload must be a dictionary. Invalid value: %@", json[UAScheduleInfoDelayKey]];
                *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                              code:UAScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
        }

        delay = [UAScheduleDelay delayWithJSON:json[UAScheduleInfoDelayKey] error:error];

        if (!delay) {
            return NO;
        }
    }

    self.triggers = triggers;
    self.limit = [limit unsignedIntegerValue];
    self.group = group;
    self.start = start;
    self.end = end;
    self.delay = delay;

    return YES;
}
@end

@implementation UAScheduleInfo

- (BOOL)isValid {
    if (!self.triggers.count || self.triggers.count > UAScheduleInfoMaxTriggers) {
        return NO;
    }

    if ([self.start compare:self.end] == NSOrderedDescending) {
        return NO;
    }

    if (self.delay && !self.delay.isValid) {
        return NO;
    }

    return YES;
}

- (instancetype)initWithBuilder:(UAScheduleInfoBuilder *)builder {
    self = [super self];
    if (self) {
        self.data = builder.data;
        self.priority = builder.priority;
        self.triggers = builder.triggers ?: @[];
        self.limit = builder.limit;
        self.group = builder.group;
        self.delay = builder.delay;
        self.start = builder.start ?: [NSDate distantPast];
        self.end = builder.end ?: [NSDate distantFuture];
    }

    return self;
}

- (BOOL)isEqualToScheduleInfo:(UAScheduleInfo *)scheduleInfo {
    if (!scheduleInfo) {
        return NO;
    }

    if (![scheduleInfo isKindOfClass:[self class]]) {
        return NO;
    }

    if (self.priority != scheduleInfo.priority) {
        return NO;
    }

    if (self.limit != scheduleInfo.limit) {
        return NO;
    }

    if (![self.start isEqualToDate:scheduleInfo.start]) {
        return NO;
    }

    if (![self.end isEqualToDate:scheduleInfo.end]) {
        return NO;
    }

    if (![self.data isEqualToString:scheduleInfo.data]) {
        return NO;
    }

    if (self.triggers != scheduleInfo.triggers && ![self.triggers isEqualToArray:scheduleInfo.triggers]) {
        return NO;
    }

    if (self.group != scheduleInfo.group && ![self.group isEqualToString:scheduleInfo.group]) {
        return NO;
    }

    if (self.delay != scheduleInfo.delay && ![self.delay isEqualToDelay:scheduleInfo.delay]) {
        return NO;
    }

    return YES;
}


#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UAScheduleInfo class]]) {
        return NO;
    }

    return [self isEqualToScheduleInfo:(UAScheduleInfo *)object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + self.limit;
    result = 31 * result + self.priority;
    result = 31 * result + [self.start hash];
    result = 31 * result + [self.end hash];
    result = 31 * result + [self.group hash];
    result = 31 * result + [self.triggers hash];
    result = 31 * result + [self.data hash];
    result = 31 * result + [self.delay hash];

    return result;
}

@end

