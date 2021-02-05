This is a collection of scripts for [REAPER](http://reaper.fm/) DAW by Paweł Łyżwa ([ply](https://github.com/ply/)).

## Install

The suggested way to install them is to use [ReaPack](https://reapack.com/)
by adding the repository: <https://ply.github.io/ReaScripts/index.xml> ([instructions](https://reapack.com/user-guide)).
You can also browse and download them [directly from GitHub](https://github.com/ply/ReaScripts).

## Usage

After installation, scripts can be run from 'Actions' window (default keyboard shortcut: `?`). All of them have names starting with `ply_`. For each action (script) it's possible there to set your own keyboard shortcuts or add to toolbars or menus. Script-specific information can be found in ReaPack's `About this package` (double-click should do the job) or script source (`Edit action` in action window).

## Support and feedback

The preferred way to report bugs or request features is the GitHub's [issue tracker](https://github.com/ply/ReaScripts/issues).
Please send code contributions as [pull requests](https://github.com/ply/ReaScripts/pulls).

## Content

Items Editing:
 - Source-Destination edit (package)
 - Synchronize and heal selected items

Items Properties:
 - Export positions of selected items to clipboard (in TSV format)

Markers:
 - Insert marker with ID larger than 10 at playback position (dialog)

Time Selection:
 - Set time selection relative to edit cursor (dialog)

Various:
 - Horizontal zoom in/out (center at edit cursor)
 - Play by loop pre-roll value from loop start/end (or current cursor position if no selection)
 - Play/stop (recording safe)
 - Playhead vs selected track items and markers window
 - `BricastiM7` directory contains my attempt to control Bricasti M7 via MIDI. Unfinished, but it might be useful for recalling parameters

JSFX:
  - 5.1 output router
  - output switcher (1 of 8 channels)