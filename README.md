## Music Importer

Allows importing music directories as playlists into Apple Music.

The tool creates playlist based on the directories present in the pointed directory. It will then recurse through and load all music files for each directory. It does not take into account sub directories as playlists.

### Running
```
./MusicImporter /path/to/music
```

### DB File
The tool creates a Songs.db file in `Application Support/MusicImporter`. If you have any issues delete this file and rerun.
