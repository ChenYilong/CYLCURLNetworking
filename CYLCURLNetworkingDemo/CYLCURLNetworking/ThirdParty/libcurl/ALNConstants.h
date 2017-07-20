//
//  ALNConstants.h
//  CYLCURLNetworking
//
//  Created by Elon Chan on 2017/3/20.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#ifndef ALNConstants_h
#define ALNConstants_h

#import <UIKit/UIKit.h>

/// Cache policies
typedef NS_ENUM(int, ALNCachePolicy) {
    /// Query from server and do not sALNe result to the local cache.
    kALNCachePolicyIgnoreCache = 0,
    
    /// Only query from the local cache.
    kALNCachePolicyCacheOnly,
    
    /// Only query from server, and sALNe result to the local cache.
    kALNCachePolicyNetworkOnly,
    
    /// Firstly query from the local cache, if fails, query from server.
    kALNCachePolicyCacheElseNetwork,
    
    /// Firstly query from server, if fails, query the local cache.
    kALNCachePolicyNetworkElseCache,
    
    /// Firstly query from the local cache, return result. Then query from server, return result. The callback will be called twice.
    kALNCachePolicyCacheThenNetwork,
} ;

typedef void (^ALNBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^ALNIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^ALNArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^ALNSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^ALNDataResultBlock)(NSData *data, NSError *error);
typedef void (^ALNImageResultBlock)(UIImage * image, NSError *error);
typedef void (^ALNDataStreamResultBlock)(NSInputStream *stream, NSError *error);
typedef void (^ALNStringResultBlock)(NSString *string, NSError *error);
typedef void (^ALNIdResultBlock)(id object, NSError *error);
typedef void (^ALNProgressBlock)(NSInteger percentDone);
typedef void (^ALNDictionaryResultBlock)(NSDictionary * dict, NSError *error);


// Errors


/*! @abstract 1: Internal server error. No information available. */
extern NSInteger const kAVErrorInternalServer;
/*! @abstract 100: The connection to the CYLCURLNetworking servers failed. */
extern NSInteger const kAVErrorConnectionFailed;
/*! @abstract 101: Object doesn't exist, or has an incorrect password. */
extern NSInteger const kAVErrorObjectNotFound;
/*! @abstract 102: You tried to find values matching a datatype that doesn't support exact database matching, like an array or a dictionary. */
extern NSInteger const kAVErrorInvalidQuery;
/*! @abstract 103: Missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters. */
extern NSInteger const kAVErrorInvalidClassName;
/*! @abstract 104: Missing object id. */
extern NSInteger const kAVErrorMissingObjectId;
/*! @abstract 105: Invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters. */
extern NSInteger const kAVErrorInvalidKeyName;
/*! @abstract 106: Malformed pointer. Pointers must be arrays of a classname and an object id. */
extern NSInteger const kAVErrorInvalidPointer;
/*! @abstract 107: Malformed json object. A json dictionary is expected. */
extern NSInteger const kAVErrorInvalidJSON;
/*! @abstract 108: Tried to access a feature only available internally. */
extern NSInteger const kAVErrorCommandUnavailable;
/*! @abstract 111: Field set to incorrect type. */
extern NSInteger const kAVErrorIncorrectType;
/*! @abstract 112: Invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter. */
extern NSInteger const kAVErrorInvalidChannelName;
/*! @abstract 114: Invalid device token. */
extern NSInteger const kAVErrorInvalidDeviceToken;
/*! @abstract 115: Push is misconfigured. See details to find out how. */
extern NSInteger const kAVErrorPushMisconfigured;
/*! @abstract 116: The object is too large. */
extern NSInteger const kAVErrorObjectTooLarge;
/*! @abstract 119: That operation isn't allowed for clients. */
extern NSInteger const kAVErrorOperationForbidden;
/*! @abstract 120: The results were not found in the cache. */
extern NSInteger const kAVErrorCacheMiss;
/*! @abstract 121: Keys in NSDictionary values may not include '$' or '.'. */
extern NSInteger const kAVErrorInvalidNestedKey;
/*! @abstract 122: Invalid file name. A file name contains only a-zA-Z0-9_. characters and is between 1 and 36 characters. */
extern NSInteger const kAVErrorInvalidFileName;
/*! @abstract 123: Invalid ACL. An ACL with an invalid format was saved. This should not happen if you use PFACL. */
extern NSInteger const kAVErrorInvalidACL;
/*! @abstract 124: The request timed out on the server. Typically this indicates the request is too expensive. */
extern NSInteger const kAVErrorTimeout;
/*! @abstract 125: The email address was invalid. */
extern NSInteger const kAVErrorInvalidEmailAddress;
/*! @abstract 137: A unique field was given a value that is already taken. */
extern NSInteger const kAVErrorDuplicateValue;
/*! @abstract 139: Role's name is invalid. */
extern NSInteger const kAVErrorInvalidRoleName;
/*! @abstract 140: Exceeded an application quota.  Upgrade to resolve. */
extern NSInteger const kAVErrorExceededQuota;
/*! @abstract 141: Cloud Code script had an error. */
extern NSInteger const kAVScriptError;
/*! @abstract 142: Cloud Code validation failed. */
extern NSInteger const kAVValidationError;
/*! @abstract 143: Product purchase receipt is missing */
extern NSInteger const kAVErrorReceiptMissing;
/*! @abstract 144: Product purchase receipt is invalid */
extern NSInteger const kAVErrorInvalidPurchaseReceipt;
/*! @abstract 145: Payment is disabled on this device */
extern NSInteger const kAVErrorPaymentDisabled;
/*! @abstract 146: The product identifier is invalid */
extern NSInteger const kAVErrorInvalidProductIdentifier;
/*! @abstract 147: The product is not found in the App Store */
extern NSInteger const kAVErrorProductNotFoundInAppStore;
/*! @abstract 148: The Apple server response is not valid */
extern NSInteger const kAVErrorInvalidServerResponse;
/*! @abstract 149: Product fails to download due to file system error */
extern NSInteger const kAVErrorProductDownloadFileSystemFailure;
/*! @abstract 150: Fail to convert data to image. */
extern NSInteger const kAVErrorInvalidImageData;
/*! @abstract 151: Unsaved file. */
extern NSInteger const kAVErrorUnsavedFile;
/*! @abstract 153: Fail to delete file. */
extern NSInteger const kAVErrorFileDeleteFailure;
/*! @abstract 200: Username is missing or empty */
extern NSInteger const kAVErrorUsernameMissing;
/*! @abstract 201: Password is missing or empty */
extern NSInteger const kAVErrorUserPasswordMissing;
/*! @abstract 202: Username has already been taken */
extern NSInteger const kAVErrorUsernameTaken;
/*! @abstract 203: Email has already been taken */
extern NSInteger const kAVErrorUserEmailTaken;
/*! @abstract 204: The email is missing, and must be specified */
extern NSInteger const kAVErrorUserEmailMissing;
/*! @abstract 205: A user with the specified email was not found */
extern NSInteger const kAVErrorUserWithEmailNotFound;
/*! @abstract 206: The user cannot be altered by a client without the session. */
extern NSInteger const kAVErrorUserCannotBeAlteredWithoutSession;
/*! @abstract 207: Users can only be created through sign up */
extern NSInteger const kAVErrorUserCanOnlyBeCreatedThroughSignUp;
/*! @abstract 208: An existing account already linked to another user. */
extern NSInteger const kAVErrorAccountAlreadyLinked;
/*! @abstract 209: User ID mismatch */
extern NSInteger const kAVErrorUserIdMismatch;
/*! @abstract 210: The username and password mismatch. */
extern NSInteger const kAVErrorUsernamePasswordMismatch;
/*! @abstract 211: Could not find user. */
extern NSInteger const kAVErrorUserNotFound;
/*! @abstract 212: The mobile phone number is missing, and must be specified. */
extern NSInteger const kAVErrorUserMobilePhoneMissing;
/*! @abstract 213: An user with the specified mobile phone number was not found. */
extern NSInteger const kAVErrorUserWithMobilePhoneNotFound;
/*! @abstract 214: Mobile phone number has already been taken. */
extern NSInteger const kAVErrorUserMobilePhoneNumberTaken;
/*! @abstract 215: Mobile phone number isn't verified. */
extern NSInteger const kAVErrorUserMobilePhoneNotVerified;
/*! @abstract 250: Linked id missing from request */
extern NSInteger const kAVErrorLinkedIdMissing;
/*! @abstract 251: Invalid linked session */
extern NSInteger const kAVErrorInvalidLinkedSession;

#define kALNDefaultNetworkTimeoutInterval 15.0

#endif /* ALNConstants_h */
