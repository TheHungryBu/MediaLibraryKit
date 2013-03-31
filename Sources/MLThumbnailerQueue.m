//
//  MLThumbnailerQueue.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLThumbnailerQueue.h"
#import "MLFile.h"
#import "MLCrashPreventer.h"


@interface ThumbnailOperation : NSOperation <VLCMediaThumbnailerDelegate>
{
    MLFile *_file;
}
@property (retain,readwrite) MLFile *file;
@end

@interface MLThumbnailerQueue ()
- (void)didFinishOperation:(ThumbnailOperation *)op;
@end

@implementation ThumbnailOperation
@synthesize file=_file;
- (id)initWithFile:(MLFile *)file;
{
    if (!(self = [super init]))
        return nil;
    self.file = file;
    return self;
}

- (void)dealloc
{
    [_file release];
    [super dealloc];
}

- (void)fetchThumbnail
{
    APLog(@"Starting THUMB %@", self.file);

    [[MLCrashPreventer sharedPreventer] willParseFile:self.file];

    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:self.file.url]];
    VLCMediaThumbnailer *thumbnailer = [VLCMediaThumbnailer thumbnailerWithMedia:media andDelegate:self];
    /* optimize thumbnails for the device */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([UIScreen mainScreen].scale==2.0) {
            thumbnailer.thumbnailWidth = 540.;
            thumbnailer.thumbnailHeight = 405.;
        } else {
            thumbnailer.thumbnailWidth = 272.;
            thumbnailer.thumbnailHeight = 204.;
        }
    } else {
        if ([UIScreen mainScreen].scale==2.0) {
            thumbnailer.thumbnailWidth = 200.;
            thumbnailer.thumbnailHeight = 150.;
        } else {
            thumbnailer.thumbnailWidth = 100.;
            thumbnailer.thumbnailHeight = 75.;
        }
    }
    [thumbnailer fetchThumbnail];
    [[MLThumbnailerQueue sharedThumbnailerQueue].queue setSuspended:YES]; // Balanced in -mediaThumbnailer:didFinishThumbnail
    [self retain]; // Balanced in -mediaThumbnailer:didFinishThumbnail:
}
- (void)main
{
    [self performSelectorOnMainThread:@selector(fetchThumbnail) withObject:nil waitUntilDone:YES];
}

- (void)endThumbnailing
{
    [[MLCrashPreventer sharedPreventer] didParseFile:self.file];
    MLThumbnailerQueue *thumbnailer = [MLThumbnailerQueue sharedThumbnailerQueue];
    [thumbnailer.queue setSuspended:NO];
    [thumbnailer didFinishOperation:self];
    [self release];
}
- (void)mediaThumbnailer:(VLCMediaThumbnailer *)mediaThumbnailer didFinishThumbnail:(CGImageRef)thumbnail
{
    mediaThumbnailer.delegate = nil;
    APLog(@"Finished thumbnail for %@", self.file.title);
    self.file.computedThumbnail = [UIImage imageWithCGImage:thumbnail];

    [self endThumbnailing];
}

- (void)mediaThumbnailerDidTimeOut:(VLCMediaThumbnailer *)mediaThumbnailer
{
    self.file.thumbnailTimeouted = YES;
    [self endThumbnailing];
}
@end

@implementation MLThumbnailerQueue
@synthesize queue=_queue;
+ (MLThumbnailerQueue *)sharedThumbnailerQueue
{
    static MLThumbnailerQueue *shared = nil;
    if (!shared) {
        shared = [[MLThumbnailerQueue alloc] init];
    }
    return shared;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _fileDescriptionToOperation = [[NSMutableDictionary alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)dealloc
{
    [_queue release];
    [_fileDescriptionToOperation release];
    [super dealloc];
}


static inline NSString *hashFromFile(MLFile *file)
{
    return [NSString stringWithFormat:@"%p", [[file objectID] URIRepresentation]];
}

- (void)didFinishOperation:(ThumbnailOperation *)op
{
    [_fileDescriptionToOperation setValue:nil forKey:hashFromFile(op.file)];
}

- (void)addFile:(MLFile *)file
{
    if ([_fileDescriptionToOperation objectForKey:hashFromFile(file)])
        return;
    if (![[MLCrashPreventer sharedPreventer] isFileSafe:file]) {
        APLog(@"'%@' is unsafe and will crash, ignoring", file.title);
        return;
    }
    ThumbnailOperation *op = [[ThumbnailOperation alloc] initWithFile:file];
    [_fileDescriptionToOperation setValue:op forKey:hashFromFile(file)];
    [self.queue addOperation:op];
    [op autorelease];
}

- (void)stop
{
    [_queue setMaxConcurrentOperationCount:0];
}

- (void)resume
{
    [_queue setMaxConcurrentOperationCount:1];
}

- (void)setHighPriorityForFile:(MLFile *)file
{
    ThumbnailOperation *op = [_fileDescriptionToOperation objectForKey:hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityHigh];
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
    ThumbnailOperation *op = [_fileDescriptionToOperation objectForKey:hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityNormal];
}
@end