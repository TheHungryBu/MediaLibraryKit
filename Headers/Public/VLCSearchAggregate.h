/*****************************************************************************
 * VLCSearchAggregate.h
 * MediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010-2018 VLC authors and VideoLAN
 * $Id$
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

@class VLCAlbum, VLCArtist, VLCGenre, VLCMediaSearchAggregate, VLCPlaylist;

@interface VLCSearchAggregate : NSObject

@property (nonatomic, copy, readonly) NSArray<VLCAlbum *> *albums;
@property (nonatomic, copy, readonly) NSArray<VLCArtist *> *artists;
@property (nonatomic, copy, readonly) NSArray<VLCGenre *> *genres;
@property (nonatomic, strong, readonly) VLCMediaSearchAggregate *mediaSearchAggregate;
@property (nonatomic, copy, readonly) NSArray<VLCPlaylist *> *playlists;

+ (instancetype)initWithAlbums:(NSArray<VLCAlbum *> *)albums
                       artists:(NSArray<VLCArtist *> *)artists
                        genres:(NSArray<VLCGenre *> *)genres
          mediaSearchAggregate:(VLCMediaSearchAggregate *)mediaSearchAggregate
                     playlists:(NSArray<VLCPlaylist *> *)playlists;

@end