// Copyright (c) 2010-2011 Zipline Games, Inc. All Rights Reserved.
// http://getmoai.com

#include "pch.h"
#import <StoreKit/StoreKit.h>
#import <moaiext-iphone/MOAIApp.h>
#import <moaiext-iphone/MOAIStoreKitListener.h>
#import <moaiext-iphone/NSData+MOAILib.h>
#import <moaiext-iphone/NSDate+MOAILib.h>
#import <moaiext-iphone/NSDictionary+MOAILib.h>
#import <moaiext-iphone/NSError+MOAILib.h>
#import <moaiext-iphone/NSString+MOAILib.h>

#include <netinet/in.h>     // INET6_ADDRSTRLEN
#include <arpa/nameser.h>   // NS_MAXDNAME
#include <netdb.h>          // getaddrinfo, struct addrinfo, AI_NUMERICHOST
#include <unistd.h>         // getopt


#define UILOCALNOTIFICATION_USER_INFO_KEY	@"userInfo"

//================================================================//
// LuaAlertView
//================================================================//
// TODO: harebrained
@implementation LuaAlertView

	//----------------------------------------------------------------//
	-( id )initWithTitle:( NSString* )title message:( NSString* )message cancelButtonTitle:( NSString* )cancelButtonTitle {
		return [ super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil ];
	}

	//----------------------------------------------------------------//
	-( void )alertView:( UIAlertView* )alertView didDismissWithButtonIndex:( NSInteger )buttonIndex {
		
		if ( self->callback ) {
			USLuaStateHandle state = self->callback.GetSelf ();
			state.Push (( int )buttonIndex + 1 );
			state.DebugCall ( 1, 0 );
		}
		[ self release ];
	}

@end

//================================================================//
// lua
//================================================================//

//----------------------------------------------------------------//
/** @name	alert
	@text	Display a modal style dialog box with one or more buttons, including a
			cancel button. This will not halt execution (this function returns immediately),
			so if you need to respond to the user's selection, pass a callback.

	@in		string title		The title of the dialog box.
	@in		string message		The message to display.
	@in		function callback	The function that will receive an integer index as which button was pressed.
	@in		string cancelTitle	The title of the cancel button.
	@in		string... buttons	Other buttons to add to the alert box.
 
*/
int MOAIApp::_alert( lua_State* L ) {
	
	USLuaState state ( L );
	
	cc8* title = state.GetValue< cc8* >(1, "Alert");
	cc8* message = state.GetValue< cc8* >(2, "");
	cc8* cancelTitle = state.GetValue< cc8*>(4, NULL);
	
	NSString *cancelButtonTitle = nil;
	if( cancelTitle )
	{
		cancelButtonTitle = [NSString stringWithUTF8String:cancelTitle];
	}
	
	// TODO: We'd love to be able to specify a list of button labels and a callback
	// to call when the button is clicked (or alternately, wrap this call into
	// a coroutine.yield() style infinite loop until we get a result)
	
	LuaAlertView *alert = [[ LuaAlertView alloc ]
						   initWithTitle:[NSString stringWithUTF8String:title ] 
						   message:[NSString stringWithUTF8String:message ]
						   cancelButtonTitle:cancelButtonTitle ];
	
	if ( state.IsType ( 3, LUA_TFUNCTION )) {
		alert->callback.SetRef ( state, 3, false );
	}	
	
	int top = state.GetTop ();
	for ( int i = 5; i <= top; ++i ) {
		cc8* button = state.GetValue < cc8* >( i, NULL );
		if ( button ) {
			[ alert addButtonWithTitle:[ NSString stringWithUTF8String:button ]];
		}
	}
	
	// Keep this alive until pressed.
	[ alert retain ];
	[ alert show ];
	
	return 0;
}

//----------------------------------------------------------------//
/**	@name	canMakePayments
	@text	Verify that app has permission to request payments.
	
	@out	bool canMakePayments
*/
int MOAIApp::_canMakePayments ( lua_State* L ) {
	USLuaState state ( L );
	
	BOOL result = [ SKPaymentQueue canMakePayments ];
	lua_pushboolean ( state, result );
	
	return 1;
}

//----------------------------------------------------------------//
/**	@name	getAppIconBadgeNumber
	@text	Return the value of the counter shown on the app icon badge.
	
	@out	number badgeNumber
*/
int MOAIApp::_getAppIconBadgeNumber ( lua_State* L ) {
	USLuaState state ( L );
	
	UIApplication* application = [ UIApplication sharedApplication ];
	lua_pushnumber ( state, application.applicationIconBadgeNumber );
	
	return 1;
}

//----------------------------------------------------------------//
/**	@name	getDirectoryInDomain
	@text	Search the platform's internal directory structure for a special directory
			as defined by the platform.
 
	@in		string domain		One of MOAIApp.DOMAIN_DOCUMENTS, MOAIApp.DOMAIN_APP_SUPPORT
	@out	string directory	The directory associated with the given domain.
*/
int MOAIApp::_getDirectoryInDomain ( lua_State* L ) {
	USLuaState state ( L );
	
	u32 dirCode = state.GetValue<u32>( 1, 0 ); 
	
	if( dirCode == 0 ) {
		lua_pushstring ( L, "" );
	}
	else {
	
		NSString *dir = [ NSSearchPathForDirectoriesInDomains ( dirCode, NSUserDomainMask, YES ) lastObject ];

		if ( ![[ NSFileManager defaultManager ] fileExistsAtPath:dir ]) {
			NSError *error;
			if ( ![[ NSFileManager defaultManager ] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error ]) {
				NSLog ( @"Error creating directory %@: %@", dir, error );
				return 0;
			}
		}
	
		[ dir toLua:L ];
	}
	return 1;
}
//----------------------------------------------------------------//
/**	@name	getNotificationThatStartedApp
	@text	Returns the notification payload of a remote notification that launched the app.
 
	@in		nil
	@out	dictionary	The notification payload that started the app
*/
int MOAIApp::_getNotificationThatStartedApp ( lua_State* L ) {

	if ( MOAIApp::Get ().mAppNotificationPayload == NULL ) {
		lua_pushnil ( L );
	}
	else {
		[ MOAIApp::Get ().mAppNotificationPayload toLua:L ];
	}
	
	return 1;
}
//----------------------------------------------------------------//
/**	@name	openURL
	@text	See UIApplication documentation.
 
	@in		string url
	@out	nil
*/
int MOAIApp::_openURL ( lua_State* L ) {
	USLuaState state ( L );
	
	cc8* url	= state.GetValue < cc8* >( 1, "" );
	
	if( url && url [ 0 ] != '\0' ) {
		[[ UIApplication sharedApplication ] openURL:[ NSURL URLWithString:[ NSString stringWithFormat: @"%s", url ]]];
	}
	
	return 1;
}

int MOAIApp::_presentLocalNotification ( lua_State* L ) {
	USLuaState state ( L );
	
	cc8* alertBody				= state.GetValue < cc8* >( 1, "" );

	UILocalNotification* notification = [[[ NSNotification alloc ] init ] autorelease ];		
	notification.alertBody			= [ NSString stringWithUTF8String:alertBody ];
	
	UIApplication* application = [ UIApplication sharedApplication ];
	[ application scheduleLocalNotification:notification ];
	
	return 0;
}

//----------------------------------------------------------------//
/**	@name	registerForRemoteNotifications
	@text	Return the app for remote notifications.
	
	@opt	number notificationTypes	Combination of MOAIApp.REMOTE_NOTIFICATION_BADGE,
										MOAIApp.REMOTE_NOTIFICATION_SOUND, MOAIApp.REMOTE_NOTIFICATION_ALERT.
										Default value is MOAIApp.REMOTE_NOTIFICATION_NONE.
	@out	nil
*/
int MOAIApp::_registerForRemoteNotifications ( lua_State* L ) {
	USLuaState state ( L );
	
	u32 types = state.GetValue < u32 >( 1, ( u32 )UIRemoteNotificationTypeNone );
	
	UIApplication* application = [ UIApplication sharedApplication ];
	[ application registerForRemoteNotificationTypes:( UIRemoteNotificationType )types ];
	
	return 0;
}

//----------------------------------------------------------------//
/**	@name	requestPaymentForProduct
	@text	Request payment for a product.
	
	@in		string productIdentifier
	@opt	number quantity				Default value is 1.
	@out	nil
*/
int MOAIApp::_requestPaymentForProduct ( lua_State* L ) {
	USLuaState state ( L );
	
	cc8* identifier = state.GetValue < cc8* >( 1, "" );
	int quantity = state.GetValue < int >( 2, 1 );
	
	if ( quantity ) {
		SKMutablePayment* payment = [ SKMutablePayment paymentWithProductIdentifier:[ NSString stringWithUTF8String:identifier ]];
		payment.quantity = quantity;
		[[ SKPaymentQueue defaultQueue ] addPayment:payment ];
	}
	return 0;
}


//----------------------------------------------------------------//
/**	@name	requestProductIdentifiers
	@text	Varify the validity of a set of products.
	
	@in		table productIdentifiers			A table of product identifiers.
	@out	nil
*/
int MOAIApp::_requestProductIdentifiers ( lua_State* L ) {
	USLuaState state ( L );
	
	NSMutableSet* productSet = [[[ NSMutableSet alloc ] init ] autorelease ];
	
	int top = state.GetTop ();
	for ( int i = 1; i <= top; ++i ) {
	
		if ( state.IsType ( i, LUA_TSTRING )) {
			cc8* identifier = state.GetValue < cc8* >( i, "" );
			[ productSet addObject :[ NSString stringWithUTF8String:identifier ]];
		}
	
		if ( state.IsType ( i, LUA_TTABLE )) {
			
			int itr = state.PushTableItr ( i );
			while ( state.TableItrNext ( itr )) {
				cc8* identifier = state.GetValue < cc8* >( -1, "" );
				[ productSet addObject :[ NSString stringWithUTF8String:identifier ]];

			}
		}
	}
	
	SKProductsRequest* request = [[ SKProductsRequest alloc ] initWithProductIdentifiers:productSet ];
	request.delegate = MOAIApp::Get ().mStoreKitListener;
	[ request start ];
	
	return 0;
}

//----------------------------------------------------------------//
/** @name	restoreCompletedTransactions
	@text	Request a restore of all purchased non-consumables from the App Store.
			Use this to retrieve a list of all previously purchased items (for example
			after reinstalling the app on a different device).
 
*/
int MOAIApp::_restoreCompletedTransactions( lua_State* L ) {
	
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

	return 0;
}

//----------------------------------------------------------------//
// TODO: test me
int MOAIApp::_scheduleLocalNotification ( lua_State* L ) {
	USLuaState state ( L );
	
	cc8* userInfo				= state.GetValue < cc8* >( 1, "" );
	cc8* fireDate				= state.GetValue < cc8* >( 2, "" ); // ISO8601
	cc8* timeZone				= state.GetValue < cc8* >( 3, 0 );
	
	cc8* alertAction			= state.GetValue < cc8* >( 5, 0 );
	cc8* alertBody				= state.GetValue < cc8* >( 6, 0 );
	bool hasAction				= state.GetValue < bool >( 4, true );
	cc8* alertLaunchImage		= state.GetValue < cc8* >( 7, 0 );
	
	int appIconBadgeNumber		= state.GetValue < int >( 8, 0 );
	cc8* soundName				= state.GetValue < cc8* >( 9, 0 );
	
	UILocalNotification* notification = [[[ NSNotification alloc ] init ] autorelease ];
	
	notification.fireDate			= [ NSDate dateFromISO8601String:[ NSString stringWithUTF8String:fireDate ]];
	notification.timeZone			= [ NSString stringWithUTF8String:timeZone ];
	
	notification.alertBody			= [ NSString stringWithUTF8String:alertBody ];
	notification.alertAction		= [ NSString stringWithUTF8String:alertAction ];	
	notification.hasAction			= hasAction;
	notification.alertLaunchImage	= [ NSString stringWithUTF8String:alertLaunchImage ];
	
	notification.applicationIconBadgeNumber	= appIconBadgeNumber;
	notification.soundName					= [ NSString stringWithUTF8String:soundName ];
	
	NSMutableDictionary* userInfoDictionary = [[[ NSMutableDictionary alloc ] init ] autorelease ];
	[ userInfoDictionary setObject:[ NSString stringWithUTF8String:userInfo ] forKey:UILOCALNOTIFICATION_USER_INFO_KEY ];
	notification.userInfo = userInfoDictionary;
	
	UIApplication* application = [ UIApplication sharedApplication ];
	[ application scheduleLocalNotification:notification ];
	
	return 0;
}

//----------------------------------------------------------------//
/**	@name	setAppIconBadgeNumber
	@text	Set (or clears) the value of the counter shown on the app icon badge.
	
	@opt	number badgeNumber		Default value is 0.
	@out	nil
*/
int MOAIApp::_setAppIconBadgeNumber ( lua_State* L ) {
	USLuaState state ( L );
	
	UIApplication* application = [ UIApplication sharedApplication ];
	application.applicationIconBadgeNumber = state.GetValue < int >( 1, 0 );
	
	return 0;
}

//----------------------------------------------------------------//
/**	@name	setListener
	@text	Set a callback to handle events of a type.
	
	@in		number event		One of MOAIApp.ERROR, MOAIApp.DID_REGISTER, MOAIApp.REMOTE_NOTIFICATION,
								MOAIApp.PAYMENT_QUEUE_TRANSACTION, MOAIApp.PRODUCT_REQUEST_RESPONSE.
	@opt	function handler
	@out	nil
*/
int MOAIApp::_setListener ( lua_State* L ) {
	USLuaState state ( L );
	
	u32 idx = state.GetValue < u32 >( 1, TOTAL );
	
	if ( idx < TOTAL ) {
		MOAIApp::Get ().mListeners [ idx ].SetRef ( state, 2, false );
	}
	
	return 0;
}

//================================================================//
// MOAIApp
//================================================================//

//----------------------------------------------------------------//
void MOAIApp::DidFailToRegisterForRemoteNotificationsWithError ( NSError* error ) {
	
	USLuaRef& callback = this->mListeners [ ERROR ];
	
	if ( callback ) {
		USLuaStateHandle state = callback.GetSelf ();
		
		[ error toLua:state ];
		
		state.DebugCall ( 1, 0 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::DidReceiveLocalNotification ( UILocalNotification* notification ) {

	USLuaRef& callback = this->mListeners [ LOCAL_NOTIFICATION ];
	
	if ( callback ) {
		USLuaStateHandle state = callback.GetSelf ();
		
		NSDictionary* userInfo = notification.userInfo;
		if ( userInfo ) {
		
			NSString* userInfoString = [ userInfo objectForKey:UILOCALNOTIFICATION_USER_INFO_KEY ];
			if ( userInfoString ) {
				[ userInfoString toLua:state ];
			}
		}
		
		state.DebugCall ( 1, 0 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::DidReceivePaymentQueueError ( NSError* error, cc8* extraInfo ) {
	
	USLuaRef& callback = this->mListeners [ PAYMENT_QUEUE_ERROR ];
	
	if ( callback ) {
		USLuaStateHandle state = callback.GetSelf ();
		
		[ error toLua:state ];
		lua_pushstring(state, extraInfo);
		
		state.DebugCall ( 2, 0 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::DidReceiveRemoteNotification ( NSDictionary* userInfo ) {

	USLuaRef& callback = this->mListeners [ REMOTE_NOTIFICATION ];
	
	if ( callback ) {
		USLuaStateHandle state = callback.GetSelf ();
		
		[ userInfo toLua:state ];
		
		state.DebugCall ( 1, 0 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::DidRegisterForRemoteNotificationsWithDeviceToken	( NSData* deviceToken ) {
	
	USLuaRef& callback = this->mListeners [ DID_REGISTER ];
	
	if ( callback ) {
		
		STLString tokenStr;
		tokenStr.hex_encode ([ deviceToken bytes ], [ deviceToken length ]);
			
		USLuaStateHandle state = callback.GetSelf ();
		lua_pushstring ( state, tokenStr );
		state.DebugCall ( 1, 0 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::DidResolveHostName( NSString* hostname, cc8* ipAddress ) {

	USLuaRef& callback = this->mListeners [ ASYNC_NAME_RESOLVE ];
	
	if ( callback ) {
		USLuaStateHandle state = callback.GetSelf ();
		
		[ hostname toLua:state ];
		state.Push ( ipAddress );
		state.DebugCall ( 2, 0 );
	}
}

//----------------------------------------------------------------//
MOAIApp::MOAIApp () {

	RTTI_SINGLE ( USLuaObject )
	
	mAppNotificationPayload = NULL;
	
	this->mStoreKitListener = [[ MOAIStoreKitListener alloc ] init ];
	[[ SKPaymentQueue defaultQueue ] addTransactionObserver:this->mStoreKitListener ];
	
	this->mReachabilityListener = [ ReachabilityListener alloc ];
	[ this->mReachabilityListener startListener ];
}

//----------------------------------------------------------------//
MOAIApp::~MOAIApp () {

	[[ SKPaymentQueue defaultQueue ] removeTransactionObserver:this->mStoreKitListener];
	[ this->mStoreKitListener release ];
}

//----------------------------------------------------------------//
void MOAIApp::OnInit () {
}

//----------------------------------------------------------------//
void MOAIApp::PaymentQueueUpdatedTransactions ( SKPaymentQueue* queue, NSArray* transactions ) {
	UNUSED ( queue );

	USLuaRef& callback = this->mListeners [ PAYMENT_QUEUE_TRANSACTION ];

	for ( SKPaymentTransaction* transaction in transactions ) {
	
		if ( callback ) {
		
			USLuaStateHandle state = callback.GetSelf ();
			this->PushPaymentTransaction ( state, transaction );
			state.DebugCall ( 1, 0 );
		}
		
		if ( transaction.transactionState != SKPaymentTransactionStatePurchasing ) {
			[[ SKPaymentQueue defaultQueue ] finishTransaction:transaction ];
		}
	}
}

//----------------------------------------------------------------//
void MOAIApp::ProductsRequestDidReceiveResponse ( SKProductsRequest* request, SKProductsResponse* response ) {

	USLuaRef& callback = this->mListeners [ PRODUCT_REQUEST_RESPONSE ];
	if ( callback ) {
		
		USLuaStateHandle state = callback.GetSelf ();
		lua_newtable ( state );
		
		int count = 1;
		for ( SKProduct* product in response.products ) {
		
			lua_pushnumber ( state, count++ );
			lua_newtable ( state );
			
			state.SetField ( -1, "localizedTitle", [ product.localizedTitle UTF8String ]);
			state.SetField ( -1, "localizedDescription", [ product.localizedDescription UTF8String ]);
			state.SetField ( -1, "price", [ product.price floatValue ]);
			state.SetField ( -1, "priceLocale", [ product.priceLocale.localeIdentifier UTF8String ]);
			state.SetField ( -1, "productIdentifier", [ product.productIdentifier UTF8String ]);
			
			lua_settable ( state, -3 );
		}
		
		// Note: If you're testing in-app purchases, chances are your product Id
		// will take time to propagate into Apple's sandbox/test environment and
		// thus the id's will be invalid for hours(?) (at the time of writing this).
		for ( NSString *invalidProductId in response.invalidProductIdentifiers )
		{
			NSLog(@"StoreKit: Invalid product id: %@" , invalidProductId);
		}
		
		state.DebugCall ( 1, 0 );
	}
	[ request autorelease ];
}

//----------------------------------------------------------------//
void MOAIApp::PushPaymentTransaction ( lua_State* L, SKPaymentTransaction* transaction ) {

	lua_newtable ( L );
	
	lua_pushstring ( L, "transactionState" );
	
	switch ( transaction.transactionState ) {
		
		case SKPaymentTransactionStatePurchasing: {
			lua_pushnumber ( L, TRANSACTION_STATE_PURCHASING );
			break;
		}
		case SKPaymentTransactionStatePurchased: {
			lua_pushnumber ( L, TRANSACTION_STATE_PURCHASED );
			break;
		}
		case SKPaymentTransactionStateFailed: {
			//int code = transaction.error.code;
			printf ("%s\n", [ transaction.error.localizedDescription UTF8String ]);
			if( transaction.error.code == SKErrorPaymentCancelled ) {
				lua_pushnumber ( L, TRANSACTION_STATE_CANCELLED );
			}
			else {
				lua_pushnumber ( L, TRANSACTION_STATE_FAILED );
			}
			break;
		}
		case SKPaymentTransactionStateRestored: {
			lua_pushnumber ( L, TRANSACTION_STATE_RESTORED );
			break;
		}
		default: {
			lua_pushnil ( L );
			break;
		}
	}
	
	lua_settable ( L, -3 );
	
	if ( transaction.payment ) {
		
		lua_pushstring ( L, "payment" );
		lua_newtable ( L );
		
		lua_pushstring ( L, "productIdentifier" );
		[ transaction.payment.productIdentifier toLua:L ];
		lua_settable ( L, -3 );
		
		lua_pushstring ( L, "quantity" );
		lua_pushnumber ( L, transaction.payment.quantity );
		lua_settable ( L, -3 );
		
		lua_settable ( L, -3 );
	}
	
	if ( transaction.transactionState == SKPaymentTransactionStateFailed ) {
		lua_pushstring ( L, "error" );
		[ transaction.error toLua:L ];
		lua_settable ( L, -3 );
	}
	
	if ( transaction.transactionState == SKPaymentTransactionStateRestored ) {
		lua_pushstring ( L, "originalTransaction" );
		this->PushPaymentTransaction ( L, transaction.originalTransaction );
		lua_settable ( L, -3 );
	}
	
	if ( transaction.transactionState == SKPaymentTransactionStatePurchased ) {
		lua_pushstring ( L, "transactionReceipt" );
		if( transaction.transactionReceipt != nil ) {
			[ transaction.transactionReceipt toLua:L ];
		}
		else {
			lua_pushnil ( L );
		}

		lua_settable ( L, -3 );
	}
	
	if (( transaction.transactionState == SKPaymentTransactionStatePurchased ) || ( transaction.transactionState == SKPaymentTransactionStateRestored )) {
		
		lua_pushstring ( L, "transactionDate" );
		[ transaction.transactionDate toLua:L ];
		lua_settable ( L, -3 );

		lua_pushstring ( L, "transactionIdentifier" );
		[ transaction.transactionIdentifier toLua:L ];
		lua_settable ( L, -3 );
	}
}

//----------------------------------------------------------------//
void MOAIApp::RegisterLuaClass ( USLuaState& state ) {

	state.SetField ( -1, "REMOTE_NOTIFICATION_NONE",	( u32 )UIRemoteNotificationTypeNone );
	state.SetField ( -1, "REMOTE_NOTIFICATION_BADGE",	( u32 )UIRemoteNotificationTypeBadge );
	state.SetField ( -1, "REMOTE_NOTIFICATION_SOUND",	( u32 )UIRemoteNotificationTypeSound );
	state.SetField ( -1, "REMOTE_NOTIFICATION_ALERT",	( u32 )UIRemoteNotificationTypeAlert );
	
	state.SetField ( -1, "ERROR",						( u32 )ERROR );
	state.SetField ( -1, "DID_REGISTER",				( u32 )DID_REGISTER );
	//state.SetField ( -1, "LOCAL_NOTIFICATION",		( u32 )LOCAL_NOTIFICATION );
	state.SetField ( -1, "PAYMENT_QUEUE_TRANSACTION",	( u32 )PAYMENT_QUEUE_TRANSACTION );
	state.SetField ( -1, "PRODUCT_REQUEST_RESPONSE",	( u32 )PRODUCT_REQUEST_RESPONSE );
	state.SetField ( -1, "PAYMENT_QUEUE_ERROR",			( u32 )PAYMENT_QUEUE_ERROR );
	state.SetField ( -1, "REMOTE_NOTIFICATION",			( u32 )REMOTE_NOTIFICATION );
	state.SetField ( -1, "ASYNC_NAME_RESOLVE",			( u32 )ASYNC_NAME_RESOLVE );
	
	state.SetField ( -1, "DOMAIN_DOCUMENTS",			( u32 )DOMAIN_DOCUMENTS );
	state.SetField ( -1, "DOMAIN_APP_SUPPORT",			( u32 )DOMAIN_APP_SUPPORT );

	state.SetField ( -1, "TRANSACTION_STATE_PURCHASING",( u32 )TRANSACTION_STATE_PURCHASING );
	state.SetField ( -1, "TRANSACTION_STATE_PURCHASED", ( u32 )TRANSACTION_STATE_PURCHASED );
	state.SetField ( -1, "TRANSACTION_STATE_FAILED",    ( u32 )TRANSACTION_STATE_FAILED );
	state.SetField ( -1, "TRANSACTION_STATE_RESTORED",  ( u32 )TRANSACTION_STATE_RESTORED );
	state.SetField ( -1, "TRANSACTION_STATE_CANCELLED", ( u32 )TRANSACTION_STATE_CANCELLED );
	
	luaL_Reg regTable[] = {
		{ "alert",								_alert },
		{ "canMakePayments",					_canMakePayments },
		{ "getAppIconBadgeNumber",				_getAppIconBadgeNumber },
		{ "getDirectoryInDomain",				_getDirectoryInDomain },
		{ "getNotificationThatStartedApp",		_getNotificationThatStartedApp },
		{ "openURL",							_openURL },
		{ "presentLocalNotification",			_presentLocalNotification },
		{ "registerForRemoteNotifications",		_registerForRemoteNotifications },
		{ "restoreCompletedTransactions",		_restoreCompletedTransactions },
		{ "requestPaymentForProduct",			_requestPaymentForProduct },
		{ "requestProductIdentifiers",			_requestProductIdentifiers },
		//{ "scheduleLocalNotification",			_scheduleLocalNotification },
		{ "setAppIconBadgeNumber",				_setAppIconBadgeNumber },
		{ "setListener",						_setListener },
		{ NULL, NULL }
	};

	luaL_register( state, 0, regTable );
}

//----------------------------------------------------------------//
void MOAIApp::Reset () {
	for ( int i = 0 ; i < TOTAL; i++ ) {
		mListeners [ i ].Clear ();
	}
}

//----------------------------------------------------------------//
void MOAIApp::SetRemoteNotificationPayload ( NSDictionary* remoteNotificationPayload ) {

	mAppNotificationPayload = remoteNotificationPayload;
}

