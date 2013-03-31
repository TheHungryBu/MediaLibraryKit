/*****************************************************************************
 * MLMovieInfoGrabber.m
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MLMovieInfoGrabber.h"

#define TMDB_HOSTNAME     "api.themoviedb.org"

#define TMDB_API_KEY      "5401cd030990fba60e1c23d2832de62e"

#define TMDB_QUERY_SEARCH @"http://%s/2.0/Movie.search?title=%@&api_key=%s"
#define TMDB_QUERY_INFO   @"http://%s/2.0/Movie.getInfo?id=%@&api_key=%s"



@interface MLMovieInfoGrabber ()
@property (readwrite, retain) NSArray *results;
@end

@implementation MLMovieInfoGrabber
@synthesize delegate=_delegate;
@synthesize results=_results;
#if !HAVE_BLOCK
@synthesize userData=_userData;
#endif
- (void)dealloc
{
#if !HAVE_BLOCK
    [_userData release];
#endif
    [_data release];
    [_connection release];
    [_results release];
#if HAVE_BLOCK
    if (_block)
        Block_release(_block);
#endif
    [super dealloc];
}

- (void)lookUpForTitle:(NSString *)title
{
    NSString *escapedString = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:TMDB_QUERY_SEARCH, TMDB_HOSTNAME, escapedString, TMDB_API_KEY]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4];
    [_connection cancel];
    [_connection release];

    [_data release];
    _data = [[NSMutableData alloc] init];

    // Keep a reference to ourself while we are alive.
    [self retain];

    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    NSAssert(_connection, @"Can't create connection");
    [request release];

}

#if HAVE_BLOCK
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)(NSError *))block
{
    Block_release(_block);
    _block = Block_copy(block);
    [self lookUpForTitle:title];
}
#endif

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    APLog(@"Did Fail %@", _delegate);
    if ([_delegate respondsToSelector:@selector(movieInfoGrabber:didFailWithError:)]) {
        APLog(@"Did Fail Calling %@", _delegate);

        [_delegate movieInfoGrabber:self didFailWithError:error];
    }

#if HAVE_BLOCK
    if (_block) {
        _block(error);

        // Release the eventual block. This prevents ref cycle.
        Block_release(_block);
        _block = NULL;
    }
#endif
    // This balances the -retain in -lookupForTitle
    [self autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:_data options:0 error:nil];

    [_data release];
    _data = nil;

    NSError *error = nil;
    NSArray *nodes = [xmlDoc nodesForXPath:@"./results/moviematches/movie" error:&error];
    if ([nodes count] > 0 ) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[nodes count]];
        for (NSXMLNode *node in nodes) {
            NSString *id = [node stringValueForXPath:@"./id"];
            if (!id)
                continue;
            NSString *title = [node stringValueForXPath:@"./title"];
            NSString *release = [node stringValueForXPath:@"./release"];
            NSString *releaseYear = nil;
            if (release) {
                NSDateFormatter *inputFormatter = [[[NSDateFormatter alloc] init] autorelease];
                [inputFormatter setDateFormat:@"yyyy-MM-dd"];
                NSDateFormatter *outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
                [outputFormatter setDateFormat:@"yyyy"];
                NSDate *releaseDate = [inputFormatter dateFromString:release];
                releaseYear = releaseDate ? [outputFormatter stringFromDate:releaseDate] : nil;
            }


            //APLog(@"%@", title);
            //APLog(TMDB_QUERY_INFO, TMDB_HOSTNAME, id, TMDB_API_KEY);
            NSString *artworkURL = [node stringValueForXPath:@"./poster[size='cover']"];
            if (!artworkURL)
                artworkURL = [node stringValueForXPath:@"./poster"];
            if (!artworkURL)
                artworkURL = [node stringValueForXPath:@"./backdrop[@size='cover']"];
            if (!artworkURL)
                artworkURL = [node stringValueForXPath:@"./backdrop"];
            NSString *shortSummary = [node stringValueForXPath:@"./short_overview"];
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              title, @"title",
                              shortSummary ?: @"", @"shortSummary",
                              releaseYear ?: @"", @"releaseYear",
                              artworkURL, @"artworkURL",
                              nil]];
        }
        self.results = array;
    }
    else {
          self.results = nil;
    }
    [xmlDoc release];

#if HAVE_BLOCK
    if (_block) {
        _block(nil);
        Block_release(_block);
        _block = NULL;
    }
#endif

    if ([_delegate respondsToSelector:@selector(movieInfoGrabberDidFinishGrabbing:)])
        [_delegate movieInfoGrabberDidFinishGrabbing:self];

    // This balances the -retain in -lookupForTitle
    [self autorelease];
}

@end
