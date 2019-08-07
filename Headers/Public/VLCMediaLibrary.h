/*****************************************************************************
 * VLCMediaLibrary.h
 * VLCMediaLibraryKit
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

#import "VLCMLObject.h"
#import "VLCMLMedia.h"

@class VLCMLFile, VLCMLLabel, VLCMLAlbum, VLCMLAlbumTrack, VLCMLArtist, VLCMLPlaylist, VLCMLHistoryEntry, VLCMLGenre, VLCMLFolder, VLCMLShow, VLCMLMovie, VLCMLSearchAggregate;

extern VLCMLIdentifier const UnknownArtistID;
extern VLCMLIdentifier const VariousArtistID;

typedef NS_ENUM (NSUInteger, VLCMLSortingCriteria) {
    /*
     * Default depends on the entity type:
     * - By track number (and disc number) for album tracks
     * - Alphabetical order for others
     */
    VLCMLSortingCriteriaDefault,
    VLCMLSortingCriteriaAlpha,
    VLCMLSortingCriteriaDuration,
    VLCMLSortingCriteriaInsertionDate,
    VLCMLSortingCriteriaLastModificationDate,
    VLCMLSortingCriteriaReleaseDate,
    VLCMLSortingCriteriaFileSize,
    VLCMLSortingCriteriaArtist,
    VLCMLSortingCriteriaPlayCount,
    VLCMLSortingCriteriaAlbum,
    VLCMLSortingCriteriaFilename,
    VLCMLSortingCriteriaTrackNumber
};

typedef NS_ENUM (NSUInteger, VLCMLInitializeResult) {

    // Everything worked out fine
    VLCMLInitializeResultSuccess,

    // Should be considered the same as Success, but is an indication of
    // unrequired subsequent calls to initialize.
    VLCMLInitializeResultAlreadyInitialized,

    // A fatal error occured, the IMediaLibrary instance should be destroyed
    VLCMLInitializeResultFailed,

    // The database was reset, the caller needs to re-configure folders to
    // discover at the bare minimum.
    VLCMLInitializeResultDbReset
};

typedef NS_ENUM (NSUInteger, VLCMLThumbnailSizeType) {
    // A small sized thumbnail. Considered to be the default value before model 17
    VLCMLThumbnailSizeTypeThumbnail,
    // A banner type thumbnail. The exact size is application dependent.
    VLCMLThumbnailSizeTypeBanner,
    // The number of different size type
    VLCMLThumbnailSizeTypeCount
};

typedef NS_ENUM (NSUInteger, VLCMLHistoryType) {
    /// The history of media analyzed by the media library
    VLCMLHistoryTypeMedia,
    /// The network streams history
    VLCMLHistoryTypeNetwork
};

typedef NS_ENUM (NSUInteger, VLCMLLogLevel) {
    VLCMLLogLevelVerbose,
    VLCMLLogLevelDebug,
    VLCMLLogLevelInfo,
    VLCMLLogLevelWarning,
    VLCMLLogLevelError
};

@class VLCMediaLibrary;

#pragma mark - VLCMediaLibraryDelegate
#pragma mark -

NS_ASSUME_NONNULL_BEGIN

@protocol VLCMediaLibraryDelegate <NSObject>

@optional

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddMedia:(NSArray<VLCMLMedia *> *)media;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didModifyMedia:(NSArray<VLCMLMedia *> *)media;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didDeleteMediaWithIds:(NSArray<NSNumber *> *)mediaIds;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddArtists:(NSArray<VLCMLArtist *> *)artists;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didModifyArtists:(NSArray<VLCMLArtist *> *)artists;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didDeleteArtistsWithIds:(NSArray<NSNumber *> *)artistsIds;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddAlbums:(NSArray<VLCMLAlbum *> *)albums;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didModifyAlbums:(NSArray<VLCMLAlbum *> *)albums;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didDeleteAlbumsWithIds:(NSArray<NSNumber *> *)albumsIds;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddPlaylists:(NSArray<VLCMLPlaylist *> *)playlists;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didModifyPlaylists:(NSArray<VLCMLPlaylist *> *)playlists;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didDeletePlaylistsWithIds:(NSArray<NSNumber *> *)playlistsIds;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddGenres:(NSArray<VLCMLGenre *> *)genres;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didModifyGenres:(NSArray<VLCMLGenre *> *)genres;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didDeleteGenresWithIds:(NSArray<NSNumber *> *)genresIds;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didStartDiscovery:(NSString *)entryPoint;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didProgressDiscovery:(NSString *)entryPoint;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didCompleteDiscovery:(NSString *)entryPoint;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didStartReload:(NSString *)entryPoint;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didCompleteReload:(NSString *)entryPoint;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didAddEntryPoint:(NSString *)entryPoint withSuccess:(BOOL)success;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didRemoveEntryPoint:(NSString *)entryPoint withSuccess:(BOOL)success;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didBanEntryPoint:(NSString *)entryPoint withSuccess:(BOOL)success;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary didUnbanEntryPoint:(NSString *)entryPoint withSuccess:(BOOL)success;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didUpdateParsingStatsWithPercent:(UInt32)percent;

- (void)medialibrary:(VLCMediaLibrary *)medialibrary didChangeIdleBackgroundTasksWithSuccess:(BOOL)success;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary thumbnailReadyForMedia:(VLCMLMedia *)media
              ofType:(VLCMLThumbnailSizeType)type withSuccess:(BOOL)success;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary historyChangedOfType:(VLCMLHistoryType)type;

@end

#pragma mark - VLCMLDeviceListerDelegate
#pragma mark -

@protocol VLCMLDeviceListerDelegate <NSObject>

@optional

- (BOOL)medialibrary:(VLCMediaLibrary *)medialibrary deviceMountedWithUUID:(NSString *)uuid
      withMountPoint:(NSString *)mountPoint;
- (void)medialibrary:(VLCMediaLibrary *)medialibrary deviceUnmountedWithUUID:(NSString *)uuid
      withMountPoint:(NSString *)mountPoint;
- (BOOL)medialibrary:(VLCMediaLibrary *)medialibrary isDeviceKnownWithUUID:(NSString *)uuid;

@end

#pragma mark - VLCMediaLibrary
#pragma mark -

@interface VLCMediaLibrary : NSObject

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, copy) NSString *thumbnailPath;
@property (nonatomic, weak) id <VLCMediaLibraryDelegate> delegate;
@property (nonatomic, weak) id <VLCMLDeviceListerDelegate> deviceListerDelegate;

#pragma mark -

- (BOOL)start;
- (VLCMLInitializeResult)setupMediaLibraryWithDatabasePath:(NSString *)databasePath
                                             thumbnailPath:(NSString *)thumbnailPath
NS_SWIFT_NAME(setupMediaLibrary(databasePath:thumbnailPath:));

- (void)setVerbosity:(VLCMLLogLevel)level;

#pragma mark -
#pragma mark Medialibrary main methods

#pragma mark - Label

- (nullable VLCMLLabel *)createLabelWithName:(NSString *)name;
- (BOOL)deleteLabel:(VLCMLLabel *)label;

#pragma mark - Media

- (nullable VLCMLMedia *)mediaWithIdentifier:(VLCMLIdentifier)identifier;
- (nullable VLCMLMedia *)mediaWithMrl:(NSURL *)mrl;
- (nullable VLCMLMedia *)addExternalMediaWithMrl:(NSURL *)mrl;
- (nullable VLCMLMedia *)addStreamWithMrl:(NSURL *)mrl;

- (nullable NSArray<VLCMLMedia *> *)audioFiles;
- (nullable NSArray<VLCMLMedia *> *)audioFilesWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                             desc:(BOOL)desc;

- (nullable NSArray<VLCMLMedia *> *)videoFiles;
- (nullable NSArray<VLCMLMedia *> *)videoFilesWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                             desc:(BOOL)desc;

#pragma mark - Album

- (nullable VLCMLAlbum *)albumWithIdentifier:(VLCMLIdentifier)identifier;

- (nullable NSArray<VLCMLAlbum *> *)albums;
- (nullable NSArray<VLCMLAlbum *> *)albumsWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                         desc:(BOOL)desc;

#pragma mark - Show

- (nullable VLCMLShow *)showWithIdentifier:(VLCMLIdentifier)identifier;

#pragma mark - Movie

- (nullable VLCMLMovie *)movieWitIdentifier:(VLCMLIdentifier)identifier;

#pragma mark - Artist

- (nullable VLCMLArtist *)artistWithIdentifier:(VLCMLIdentifier)identifier;

/**
 * @brief List all artists that have at least an album.
 * Artists that only appear on albums as guests won't be listed from here, but will be
 * returned when querying an album for all its appearing artists
 * @param includeAll If true, all artists including those without album
 *                   will be returned. If false, only artists which have
 *                   an album will be returned.
 */
- (nullable NSArray<VLCMLArtist *> *)artists:(BOOL)includeAll;

/**
 * @brief List all artists that have at least an album.
 * Artists that only appear on albums as guests won't be listed from here, but will be
 * returned when querying an album for all its appearing artists
 * @param sort A sorting criteria. So far, this is ignored, and artists are sorted by lexial order
 * @param desc If true, the provided sorting criteria will be reversed.
 * @param includeAll If true, all artists including those without album
 *                   will be returned. If false, only artists which have
 *                   an album will be returned.
 */
- (nullable NSArray<VLCMLArtist *> *)artistsWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                           desc:(BOOL)desc all:(BOOL)includeAll;

#pragma mark - Genre

- (nullable VLCMLGenre *)genreWithIdentifier:(VLCMLIdentifier)identifier;
- (nullable NSArray<VLCMLGenre *> *)genres;
- (nullable NSArray<VLCMLGenre *> *)genresWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                         desc:(BOOL)desc;

#pragma mark - Playlist

- (nullable VLCMLPlaylist *)playlistWithIdentifier:(VLCMLIdentifier)identifier;
- (nullable NSArray<VLCMLPlaylist *> *)playlists;
- (nullable NSArray<VLCMLPlaylist *> *)playlistsWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                               desc:(BOOL)desc;

- (nullable VLCMLPlaylist *)createPlaylistWithName:(NSString *)name;
- (BOOL)deletePlaylistWithIdentifier:(VLCMLIdentifier)identifier;

#pragma mark - History

- (nullable NSArray<VLCMLMedia *> *)history;
- (nullable NSArray<VLCMLMedia *> *)streamHistory;
- (BOOL)clearHistory;

#pragma mark - Search

/**
 * @brief searchMedia, searchAudio, and searchVideo search for some media, based on a pattern.
 * @param pattern A 3 character or more pattern that will be matched against the media's title
 *                or filename if no title was set for this media.
 * @param params Some query parameters. Valid sorting criteria are:
 *               - Duration
 *               - InsertionDate
 *               - ReleaseDate
 *               - PlayCount
 *               - Filename
 *               - LastModificationDate
 *               - FileSize
 *              Default sorting parameter uses the media's title.
 *              Passing nullptr will default to default ascending sort
 *
 * Only media that were discovered by the medialibrary will be included.
 * For instance, media that are added explicitely, playlist items that
 * point to remote content, will *not* be included
 */

- (nullable NSArray<VLCMLMedia *> *)searchMedia:(NSString *)pattern;
- (nullable NSArray<VLCMLMedia *> *)searchMedia:(NSString *)pattern
                                           sort:(VLCMLSortingCriteria)criteria desc:(BOOL)desc;

- (nullable NSArray<VLCMLPlaylist *> *)searchPlaylistsByName:(NSString *)name;
- (nullable NSArray<VLCMLPlaylist *> *)searchPlaylistsByName:(NSString *)name
                                                        sort:(VLCMLSortingCriteria)criteria
                                                        desc:(BOOL)desc;

- (nullable NSArray<VLCMLAlbum *> *)searchAlbumsByPattern:(NSString *)pattern;
- (nullable NSArray<VLCMLAlbum *> *)searchAlbumsByPattern:(NSString *)pattern
                                                     sort:(VLCMLSortingCriteria)criteria
                                                     desc:(BOOL)desc;

- (nullable NSArray<VLCMLGenre *> *)searchGenreByName:(NSString *)name;
- (nullable NSArray<VLCMLGenre *> *)searchGenreByName:(NSString *)name
                                                 sort:(VLCMLSortingCriteria)criteria desc:(BOOL)desc;

- (nullable NSArray<VLCMLArtist *> *)searchArtistsByName:(NSString *)name all:(BOOL)includeAll;
- (nullable NSArray<VLCMLArtist *> *)searchArtistsByName:(NSString *)name all:(BOOL)includeAll
                                                    sort:(VLCMLSortingCriteria)criteria
                                                    desc:(BOOL)desc;

- (nullable NSArray<VLCMLFolder *> *)searchFoldersWithPattern:(NSString *)pattern;
- (nullable NSArray<VLCMLFolder *> *)searchFoldersWithPattern:(NSString *)pattern
                                                         type:(VLCMLMediaType)type;

- (nullable NSArray<VLCMLFolder *> *)searchFoldersWithPattern:(NSString *)pattern
                                              sortingCriteria:(VLCMLSortingCriteria)criteria
                                                         desc:(BOOL)desc;
- (nullable NSArray<VLCMLFolder *> *)searchFoldersWithPattern:(NSString *)pattern
                                                         type:(VLCMLMediaType)type
                                              sortingCriteria:(VLCMLSortingCriteria)criteria
                                                         desc:(BOOL)desc;

- (VLCMLSearchAggregate *)search:(NSString *)pattern;
- (VLCMLSearchAggregate *)search:(NSString *)pattern
                            sort:(VLCMLSortingCriteria)criteria desc:(BOOL)desc;


#pragma mark - Discover

/**
 * @brief Launch a discovery on the provided entry point.
 * The actuall discovery will run asynchronously, meaning this method will immediatly return.
 * Depending on which discoverer modules where provided, this might or might not work
 * \note This must be called after start()
 * @param entryPoint What to discover.
 */
- (void)discoverOnEntryPoint:(NSString *)path;

/**
 * @brief enableDiscoverNetwork Enable discovery of network shares
 *
 * This can be called at any time, but won't have any effect before
 * initialize() has been called.
 * When disabling network discovery, all content that was discovered on
 * the network will be marked as non-present, meaning they won't be
 * returned until network discovery gets enabled again.
 * As far as the user is concerned, this is equivalent to (un)plugging
 * a USB drive, in the sense that the medialibrary will still store
 * information about network content and won't have to discover/parse it
 * again.
 */
- (void)enableDiscoverNetwork:(BOOL)enable;
- (nullable NSArray<VLCMLFolder *> *)entryPoints;
- (void)removeEntryPointWithPath:(NSString *)path;

#pragma mark - Folder

- (nullable VLCMLFolder *)folderWithIdentifier:(VLCMLIdentifier)identifier;
- (nullable VLCMLFolder *)folderAtMrl:(NSURL *)mrl;

/**
 * @brief folders Returns a flattened list of all folders of any type
 * @return An array of VLCMLFolder object
 */
- (NSArray<VLCMLFolder *> *)folders;

/**
 * @brief folders Returns a flattened list of all folders containing at least a media of a given type
 * @param type A required type of media, or VLCMediaTypeUnknown if any media type is fine.
 * @return An array of VLCMLFolder object
 *
 * This is flattened, ie.
 * ├── a
 * │   └── w
 * │       └── x
 * │           └── y
 * │               └── z
 * │                   └── DogMeme.avi
 * ├── c
 * │   └── NakedMoleRat.asf
 *
 * would return a query containing 'z' and 'c' as the other folders are
 * not containing any media.
 * In case a non flattened list is desired, the
 * entryPoints() & VLCMLFolder::subFolders() methods should be used.
 */
- (nullable NSArray<VLCMLFolder *> *)foldersOfType:(VLCMLMediaType)type;

- (nullable NSArray<VLCMLFolder *> *)foldersWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                           desc:(BOOL)desc;
- (nullable NSArray<VLCMLFolder *> *)foldersWithSortingCriteria:(VLCMLSortingCriteria)criteria
                                                           type:(VLCMLMediaType)type
                                                           desc:(BOOL)desc;


/**
 * @brief banFolderWithPath will prevent an entry point folder from being discovered.
 * If the folder was already discovered, it will be removed prior to the ban, and all
 * associated media will be discarded.
 * * @note This method is asynchronous and will run after all currently stacked
 * discovery/ban/unban operations have completed.
 */
- (void)banFolderWithPath:(NSString *)path;

/**
 * @brief unbanFolderWithEntryPoint Unban an entrypoint.
 * In case this entry point was indeed previously banned, this will issue a reload of
 * that entry point
 * @param entryPoint The entry point to unban
 * @note This method is asynchronous and will run after all currently stacked
 * discovery/ban/unban operations have completed.
 */
- (void)unbanFolderWithEntryPoint:(NSString *)entryPoint;

#pragma mark - Thumbnail

/**
 * @brief enableFailedThumbnailRegeneration Allow failed thumbnail attempt to be retried
 *
 * This will not attempt to regenerate the thumbnail immediatly, requestThumbnail
 * still has to be called afterward.
 */
- (void)enableFailedThumbnailRegeneration;

#pragma mark - Logger

#pragma mark - Background Operation

/**
 * @brief pauseBackgroundOperations Will stop potentially CPU intensive background
 * operations, until resumeBackgroundOperations() is called.
 * If an operation is currently running, it will finish before pausing.
 */
- (void)pauseBackgroundOperations;

/**
 * @brief resumeBackgroundOperations Resumes background tasks, previously
 * interrupted by pauseBackgroundOperations().
 */
- (void)resumeBackgroundOperations;

#pragma mark - Reload

- (void)reload;
- (void)reloadEntryPoint:(NSString *)entryPoint;

#pragma mark - Parser

/**
 * @brief forceParserRetry Forces a re-run of all metadata parsers and resets any
 * unterminated file retry count to 0, granting them 3 new tries at being parsed
 */
- (void)forceParserRetry;

#pragma mark - Scan

/**
 * @brief forceRescan Deletes all entities except Media and Playlist, and
 *                    forces all media to be rescanned.
 *
 * This can be called anytime after the medialibrary has been initialized. * It will make all held instances outdated. Those should be considered
 * as invalid the moment this method returns.
 */
- (void)forceRescan;

#pragma mark - DeviceLister

@end

NS_ASSUME_NONNULL_END
