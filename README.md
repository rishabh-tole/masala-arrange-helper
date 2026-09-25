# Masala Arrange Helper 1.1.0

A MuseScore Studio 4 plugin for building, editing, previewing, and inserting four-part vocal voicings for:

- Tenor 1
- Tenor 2
- Baritone
- Bass

The plugin includes a live four-staff voicing preview, internal chord-card drag-and-drop, per-part Root/3rd/5th/7th assignment, exact octave control, automatic close/spread/smooth voicings, warnings, score-chord analysis, score insertion, and temporary playback preview.

## Install

### 1. Extract the ZIP

Extract `MasalaArrangeHelper-1.1.0.zip`. Keep the resulting `MasalaArrangeHelper` folder intact.

The important file path should end like this:

```text
MasalaArrangeHelper/MasalaArrangeHelper.qml
```

### 2. Copy the folder into MuseScore's plugin folder

**Windows**

```text
C:\Users\YOUR_USER_NAME\Documents\MuseScore4\Plugins\MasalaArrangeHelper\
```

**macOS**

```text
~/Documents/MuseScore4/Plugins/MasalaArrangeHelper/
```

**Linux**

```text
~/Documents/MuseScore4/Plugins/MasalaArrangeHelper/
```

Create the `Plugins` folder when it does not already exist.

### 3. Enable the plugin

1. Start or restart MuseScore Studio 4.
2. Open **Home → Plugins**, or open **Plugins → Manage plugins** from the score view.
3. Find **Masala Arrange Helper**.
4. Enable its checkbox.
5. Open a score, then choose **Plugins → Masala Arrange Helper**.

Masala Arrange Helper opens as a dockable, modeless panel. Resize it from its
edges, dock it in MuseScore, or leave it floating while editing the score.

You can assign it a keyboard shortcut from MuseScore's shortcut preferences by searching for the plugin name.

## Prepare a score

The plugin works with one or more staves. On scores with at least four staves,
it maps to the bottom four by default in this top-to-bottom vocal order:

```text
Fourth staff from bottom: Tenor 1
Third staff from bottom:  Tenor 2
Second staff from bottom: Baritone
Bottom staff:             Bass
```

For one-staff scores, all four parts default to that staff. For two staves,
T1/T2 share the upper staff and Baritone/Bass share the lower. For three staves,
Baritone/Bass share the third staff. Change the mapping controls in **Advanced**
to use any layout. Parts assigned to the same staff form one block chord.

## First-use walkthrough

1. Open a score with one or more staves.
2. Run **Plugins → Masala Arrange Helper**.
3. Choose a key and mode.
4. Click palette cards to build a progression. You can also drag them into the progression lane.
5. Click a progression card to edit it.
6. Watch the live staves while choosing each part's chord member and octave.
7. Try **Smooth**, **Close**, or **Spread**.
8. Press **Hear chord** to hear it through the score's current instruments.
9. In the MuseScore score, select the rest or note where insertion should begin.
10. Press **Insert chord** or **Insert progression**.

## Simple, resizable interface

The main workflow is one vertically scrollable page:

```text
Harmony → Palette → Progression → Insert → Voicing + staff preview
```

At wide widths, voicing controls and staff preview sit side by side. At narrow widths, staff preview moves below voicing controls. Horizontal scrolling is disabled for the page.

**Advanced** starts collapsed. Open it for accidental spelling, custom chords, fine tone/octave movement, role rotation, staff mapping, and score-chord analysis.

## Live staff preview

The selected chord appears on four separate staves:

```text
T1:       treble clef
T2:       treble clef
Baritone: treble clef
Bass:     bass clef
```

Each voicing edit updates noteheads, stems, accidentals, ledger lines, and pitch labels immediately. Out-of-range notes appear in red. The preview is a compact pitch view drawn inside the plugin; final spacing and engraving still come from MuseScore after insertion.

## Selecting the insertion point

The plugin can use:

- A selected note
- A selected rest
- A selected chord
- The start of a selected range

A blue range or a visibly selected score item is the safest starting point. If the plugin says it cannot find an insertion beat, click a rest at the intended location and try again.

## Editing who sings Root, 3rd, 5th, and 7th

Select a progression card. Every part row contains a **Chord member** menu and an **Octave** control.

Example for C7:

```text
T1:       flat 7th, octave 4  = B-flat 4
T2:       5th, octave 4       = G4
Baritone: 3rd, octave 3       = E3
Bass:     Root, octave 2      = C2
```

The **tone** buttons move one singer to the next or previous available chord tone. The **±8va** buttons keep the same chord member and move it by an octave.

**Rotate roles** shifts the chord-member assignments among all four parts while trying to keep each part near its prior register. Warnings identify crossings, missing chord members, or range issues.

## Analyze an existing score chord

1. Add or select a progression card.
2. Select a score beat containing one note per assigned part. Shared-staff notes must be in one chord.
3. Press **Analyze notes at score selection**.

The plugin detects a supported root and quality, then loads the exact Bass, Baritone, T2, and T1 notes into the card.

## Preview behavior

MuseScore's public QML plugin API does not expose a direct arbitrary-note audition call. Preview therefore:

1. Adds a temporary measure at the end of the score.
2. Writes the four preview notes there.
3. Plays that selected range.
4. Stops and invokes Undo to remove the temporary measure.

Do not close MuseScore during the brief preview. If the temporary measure ever remains because playback or Undo was interrupted, press `Ctrl+Z` on Windows/Linux or `Command+Z` on macOS once.

## Insertion behavior

Insertion writes voice 1 on every mapped staff. Parts sharing a staff are added
to the same MuseScore chord cell; exact unisons become one visible notehead. A
single chord is grouped as one undo step. A complete progression is also grouped
as one undo step.

MuseScore decides how newly entered notes interact with existing material. When testing in an occupied passage, save first or work on a copy.

## Default warning ranges

```text
Bass:      E2–C4
Baritone:  A2–G4
Tenor 2:   C3–B4
Tenor 1:   G3–E5
```

These are suggestions only. The plugin still allows any MIDI octave supported by the controls.

## Supported chord qualities

Major, minor, diminished, augmented, dominant 7, major 7, minor 7, half-diminished 7, diminished 7, minor-major 7, augmented-major 7, sus2, and sus4.

## Current limitations

- Drag-and-drop works within the plugin, not directly onto the MuseScore page.
- Progressions are not saved after the plugin dialog closes.
- Version 1.1 writes notes only; it does not add chord symbols or lyrics.
- The live staff preview shows pitch placement, not MuseScore's full engraving output.
- Preview depends on MuseScore's playback actions and Undo behavior.

## Validation status

The source has passed:

- Delimiter, quote, and comment balance checks
- JavaScript syntax checking for all 75 named functions
- Palette and duration tests
- Key-transposition tests
- Chord-member rotation and tone-stepping tests
- Automatic voicing tests for all 13 supported qualities in all 12 roots, totaling 156 quality/root cases
- Responsive-layout, collapsed-Advanced, drag-and-drop, and staff-preview contract tests
- Staff-placement tests for treble/bass clefs, accidentals, and ledger lines
- Shared-staff block-chord grouping, deduplication, defaults, and analysis tests

MuseScore Studio 4.6.3 loaded version 1.1.0 without a QML parse failure.
Shared-staff insertion, block-chord output, and the revised action layout passed
an in-app interaction check.

## Files

```text
MasalaArrangeHelper.qml  Plugin source
StaffPreview.js          Staff-preview pitch and ledger-line helpers
ScoreInsertion.js        Shared-staff mapping and block-chord helpers
SPEC.md                  Full product and technical specification
README.md                Installation and use guide
VALIDATION.md            Static test record and runtime checklist
tests/                   Node-based UI and structure checks
LICENSE                   GNU GPL version 3
```
# masala-arrange-helper
