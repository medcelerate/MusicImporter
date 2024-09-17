//
//  main.m
//  MusicImporter
//
//  Created by Evan Clark on 9/15/24.
//

#import <Foundation/Foundation.h>
#import "Music.h"


NSArray<NSString *> *getTopLevelDirectoriesAtPath(NSString *path) {
    NSMutableArray<NSString *> *directories = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    // Get the contents of the directory
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];

    if (error) {
        NSLog(@"Error reading contents of directory %@: %@", path, error.localizedDescription);
        return nil;
    }

    // Iterate over the contents
    for (NSString *item in contents) {
        NSString *fullPath = [path stringByAppendingPathComponent:item];
        BOOL isDirectory = NO;

        // Check if the item is a directory
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            [directories addObject:item];
        }
    }
    return [directories copy];
}

int main(int argc, const char * argv[]) {
    
    if (argc < 2) {
        printf("Usage: %s <FilePath>\n", argv[0]);
        return 1;
    }
    
    printf("Starting Music Importer\n");
    
    @autoreleasepool {
        MusicApplication* MusicApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.Music"];
        
        if (MusicApp == nil) {
            NSLog(@"Music App not found");
            return 2;
        }
        
        NSLog(@"Music App found");
        
        SBElementArray *Sources = MusicApp.sources;
        MusicSource *Library = nil;
        
        for (MusicSource *source in Sources) {
            if ([source.name isEqualToString:@"Library"]) {
                Library = source;
                break;
            }
        }
        
        if (Library == nil) {
            NSLog(@"Library not found");
        }
        
        NSString *path = [NSString stringWithUTF8String:argv[1]];
        
        NSArray<NSString *> *directories = getTopLevelDirectoriesAtPath(path);
        
        if (directories == nil) {
            return 3;
        }
        
        if (directories.count == 0) {
            NSLog(@"No directories found at %@", path);
            return 5;
        }
        
        for (NSString *directory in directories) {
            MusicPlaylist* Playlist = nil;
            NSLog(@"Found Directory %@", directory);
            //Create an apple music playlist here from the top level directory name if it doesn't exist already
            bool isNew = true;
            for (MusicPlaylist* __strong LPlaylist in MusicApp.playlists) {
                NSString* PlaylistName = [LPlaylist name];
                if ([PlaylistName isEqualToString:directory]) {
                    NSLog(@"Playlist %@ already exists", directory);
                    Playlist = LPlaylist;
                    isNew = false;
                    break;
                }
            }
            
            if (isNew) {
                //Create playlist folder
                Playlist = [[[MusicApp classForScriptingClass:@"playlist"] alloc] init];
                [MusicApp.playlists insertObject: Playlist atIndex:0];
                [Playlist setName:directory];
                NSLog(@"Created Playlist %@", directory);
            }
            
            if (Playlist == nil) {
                NSLog(@"Playlist not found");
                return 10;
            }
            
            
            //turn path into a NSURL
            //Join  directory with path
            NSString *subFullPath = [path stringByAppendingPathComponent:directory];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            
            // Get the contents of the directory
            
            NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:subFullPath error:&error];
            
            if (error) {
                NSLog(@"Error reading contents of directory %@: %@", subFullPath, error.localizedDescription);
                return 4;
            }
            //Recurse through directory and get all files

            for (NSString *item in contents) {
                NSString *fullItemPath = [subFullPath stringByAppendingPathComponent:item];
                BOOL isDirectory = NO;
                
                // Check if the item is a directory
                if ([fileManager fileExistsAtPath:fullItemPath isDirectory:&isDirectory] && !isDirectory) {
                    //Check for audio file suffixes
                    if (![fullItemPath.pathExtension isEqualToString:@"mp3"] && ![fullItemPath.pathExtension isEqualToString:@"m4a"] && ![fullItemPath.pathExtension isEqualToString:@"wav"] &&
                        ![fullItemPath.pathExtension isEqualToString:@"aif"] &&
                        ![fullItemPath.pathExtension isEqualToString:@"aiff"]
                        ) {
                        continue;
                    }
                    //Add the song to the playlist
                    bool isSongInPlaylist = false;
                    for (MusicFileTrack* track in [Playlist tracks]) {
                        // Get last item of NSURL
                        NSString* FileName = [track.location lastPathComponent];
                        NSString* itemFileName = [fullItemPath lastPathComponent];
                        if ([FileName isEqualToString:itemFileName]) {
                            isSongInPlaylist = true;
                            break;
                        }
                    }
                    //convert fullitempath to NSARRAY of NSURL
                    NSURL* url = [NSURL fileURLWithPath:fullItemPath];
                    NSArray<NSURL *> *urls = [NSArray arrayWithObject:url];
                    if (!isSongInPlaylist) {
                        NSLog(@"Found New Song: %@", item);
                        [MusicApp add: urls to:Playlist];
                        NSLog(@"Added %@ to %@", item, directory);
                    }
                } else if (isDirectory) {
                    
                    //Recurse through directory and get all files
                    NSArray<NSString *> *subContents = [fileManager contentsOfDirectoryAtPath:fullItemPath error:&error];
                    
                    if (error) {
                        NSLog(@"Error reading contents of directory %@: %@", fullItemPath, error.localizedDescription);
                        return 4;
                    }
                    
                    for (NSString *subItem in subContents) {
                        NSString *subFullItemPath = [fullItemPath stringByAppendingPathComponent:subItem];
                        BOOL isSubDirectory = NO;
                        
                        // Check if the item is a directory
                        if ([fileManager fileExistsAtPath:subFullItemPath isDirectory:&isSubDirectory] && !isSubDirectory) {
                            if (![subFullItemPath.pathExtension isEqualToString:@"mp3"] && ![subFullItemPath.pathExtension isEqualToString:@"m4a"] && ![subFullItemPath.pathExtension isEqualToString:@"wav"] &&
                                ![subFullItemPath.pathExtension isEqualToString:@"aif"] &&
                                ![subFullItemPath.pathExtension isEqualToString:@"aiff"]
                                ) {
                                continue;
                            }
                            //Add the song to the playlist
                            bool isSongInPlaylist = false;
                            for (MusicFileTrack* track in [Playlist tracks]) {
                                // Get last item of NSURL
                                NSString* FileName = [track.location lastPathComponent];
                                NSString* itemFileName = [subFullItemPath lastPathComponent];
                                if ([FileName isEqualToString:itemFileName]) {
                                    isSongInPlaylist = true;
                                    break;
                                }
                            }
                            //convert fullitempath to NSARRAY of NSURL
                            NSURL* url = [NSURL fileURLWithPath:subFullItemPath];
                            NSArray<NSURL *> *urls = [NSArray arrayWithObject:url];
                            if (!isSongInPlaylist) {
                                NSLog(@"Found New Song: %@", subItem);
                                [MusicApp add: urls to:Playlist];
                                NSLog(@"Added %@ to %@", subItem, directory);
                            }
                        }
                    }
                }
            }
               
        }
        return 0;
    }
}
