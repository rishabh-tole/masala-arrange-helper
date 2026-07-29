# Masala Arrange Helper 1.0.0

A MuseScore Studio 4 plugin for building, editing, previewing, and inserting four-part vocal voicings for:

- Tenor 1
- Tenor 2
- Baritone
- Bass

The plugin includes internal chord-card drag-and-drop, per-part Root/3rd/5th/7th assignment, exact octave control, automatic close/spread/smooth voicings, warnings, score-chord analysis, score insertion, and temporary playback preview.

## Install

### 1. Extract the ZIP

Extract `MasalaArrangeHelper-1.0.0.zip`. Keep the resulting `MasalaArrangeHelper` folder intact.

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

You can assign it a keyboard shortcut from MuseScore's shortcut preferences by searching for the plugin name.

## Prepare a score

The plugin needs at least four staves. Its default mapping is:

```text
Staff 1: Tenor 1
Staff 2: Tenor 2
Staff 3: Baritone
Staff 4: Bass
```

The staves do not need those exact names. Change the four mapping controls in the plugin when your score uses a different order.

## First-use walkthrough

1. Open a four-staff score.
2. Run **Plugins → Masala Arrange Helper**.
3. Choose a key and mode.
4. Click palette cards to build a progression. You can also drag them into the progression lane.
5. Click a progression card to edit it.
6. For each part, choose a chord member such as Root, 3rd, 5th, or 7th.
7. Set the exact octave, or use the tone and octave movement buttons.
8. Try **Smooth from previous**, **Close**, **Spread**, or **Rotate roles**.
9. Press **Preview selected chord** to hear it through the score's current instruments.
10. In the MuseScore score, select the rest or note where insertion should begin.
11. Press **Insert selected chord** or **Insert full progression**.

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
2. Select a score beat containing one note on each mapped vocal staff.
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

Insertion writes voice 1 on the four mapped staves. A single chord is grouped as one undo step. A complete progression is also grouped as one undo step.

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
- Version 1.0 writes notes only; it does not add chord symbols or lyrics.
- It assumes one monophonic vocal note in voice 1 on each mapped staff.
- Preview depends on MuseScore's playback actions and Undo behavior.

## Validation status

The source has passed:

- Delimiter, quote, and comment balance checks
- JavaScript syntax checking for all 75 named functions
- Palette and duration tests
- Key-transposition tests
- Chord-member rotation and tone-stepping tests
- Automatic voicing tests for all 13 supported qualities in all 12 roots, totaling 156 quality/root cases

MuseScore Studio itself is not available in the build environment used for this package. The QML was therefore not launched in the actual application here. The implementation follows the current MuseScore 4 plugin import, score-cursor, selection, command-group, and playback-command APIs, but the first in-app launch is still the final runtime test.

## Files

```text
MasalaArrangeHelper.qml  Plugin source
SPEC.md                  Full product and technical specification
README.md                Installation and use guide
VALIDATION.md            Static test record and runtime checklist
LICENSE                   GNU GPL version 3
```
