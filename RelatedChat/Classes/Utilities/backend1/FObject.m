//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "FObject.h"
#import "NSError+Util.h"

@implementation FObject

@synthesize path, subpath, dictionary;

#pragma mark - Class methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (instancetype)objectWithPath:(NSString *)path;
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[FObject alloc] initWithPath:path];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (instancetype)objectWithPath:(NSString *)path dictionary:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[FObject alloc] initWithPath:path dictionary:dictionary];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (instancetype)objectWithPath:(NSString *)path Subpath:(NSString *)subpath;
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[FObject alloc] initWithPath:path Subpath:subpath];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (instancetype)objectWithPath:(NSString *)path Subpath:(NSString *)subpath dictionary:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[FObject alloc] initWithPath:path Subpath:subpath dictionary:dictionary];
}

#pragma mark - Instance methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (instancetype)initWithPath:(NSString *)path_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [self initWithPath:path_ Subpath:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (instancetype)initWithPath:(NSString *)path_ dictionary:(NSDictionary *)dictionary_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [self initWithPath:path_ Subpath:nil dictionary:dictionary_];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (instancetype)initWithPath:(NSString *)path_ Subpath:(NSString *)subpath_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	if (self)
	{
		path = path_;
		subpath = subpath_;
		dictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (instancetype)initWithPath:(NSString *)path_ Subpath:(NSString *)subpath_ dictionary:(NSDictionary *)dictionary_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *object = [self initWithPath:path_ Subpath:subpath_];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[dictionary_ enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	{
		if ([obj isKindOfClass:[NSArray class]])
		{
			object[key] = [NSMutableArray arrayWithArray:obj];
		}
		else if ([obj isKindOfClass:[NSDictionary class]])
		{
			object[key] = [NSMutableDictionary dictionaryWithDictionary:obj];
		}
		else object[key] = obj;
	}];
	return object;
}

#pragma mark - Accessors

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)objectForKeyedSubscript:(NSString *)key
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [dictionary objectForKey:key];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[dictionary setObject:object forKey:key];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)objectId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return dictionary[@"objectId"];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)objectIdInit
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (dictionary[@"objectId"] == nil)
	{
		FIRDatabaseReference *reference = [self databaseReference];
		dictionary[@"objectId"] = reference.key;
	}
	return dictionary[@"objectId"];
}

#pragma mark - Save methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)saveInBackground
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self saveInBackground:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)saveInBackground:(void (^)(NSError *error))block
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *reference = [self databaseReference];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dictionary[@"objectId"] == nil)
		dictionary[@"objectId"] = reference.key;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dictionary[@"createdAt"] == nil)
		dictionary[@"createdAt"] = @(interval);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dictionary[@"updatedAt"] = @(interval);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (block != nil)
	{
		[reference updateChildValues:dictionary withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) { block(error); }];
	}
	else [reference updateChildValues:dictionary];
}

#pragma mark - Update methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateInBackground
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self updateInBackground:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateInBackground:(void (^)(NSError *error))block
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *reference = [self databaseReference];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dictionary[@"objectId"] != nil)
	{
		dictionary[@"updatedAt"] = @([[NSDate date] timeIntervalSince1970]);
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (block != nil)
		{
			[reference updateChildValues:dictionary withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) { block(error); }];
		}
		else [reference updateChildValues:dictionary];
	}
	else if (block != nil) block([NSError description:@"Object cannot be updated." code:101]);
}

#pragma mark - Delete methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteInBackground
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self deleteInBackground:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteInBackground:(void (^)(NSError *error))block
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *reference = [self databaseReference];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dictionary[@"objectId"] != nil)
	{
		if (block != nil)
		{
			[reference removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) { block(error); }];
		}
		else [reference removeValue];
	}
	else if (block != nil) block([NSError description:@"Object cannot be deleted." code:102]);
}

#pragma mark - Fetch methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)fetchInBackground
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self fetchInBackground:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)fetchInBackground:(void (^)(NSError *error))block
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *reference = [self databaseReference];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[reference observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			dictionary = [NSMutableDictionary dictionaryWithDictionary:snapshot.value];
			if (block != nil) block(nil);
		}
		else if (block != nil) block([NSError description:@"Object not found." code:103]);
	}];
}

#pragma mark - Private methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (FIRDatabaseReference *)databaseReference
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *reference;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (subpath == nil)
		reference = [[FIRDatabase database] referenceWithPath:path];
	else reference = [[[FIRDatabase database] referenceWithPath:path] child:subpath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dictionary[@"objectId"] == nil)
		return [reference childByAutoId];
	else return [reference child:dictionary[@"objectId"]];
}

@end

