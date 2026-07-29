# Masala Arrange Helper — Product and Technical Specification

**Version:** 1.0.0  
**Target:** MuseScore Studio 4.x  
**Plugin type:** QML dialog plugin  
**Primary ensemble:** Bass, Baritone, Tenor 2, Tenor 1

## 1. Product summary

Masala Arrange Helper is a four-part vocal arranging workbench inside MuseScore Studio. It lets an arranger choose a key and mode, build a chord progression from compact chord cards, decide exactly which singer has each chord member, see every pitch on a live staff, audition the voicing, and write the result onto four mapped score staves.

The central design principle is that a chord is not just a symbol. Every chord card stores a complete four-note voicing:

- Bass chord member and octave
- Baritone chord member and octave
- Tenor 2 chord member and octave
- Tenor 1 chord member and octave
- Chord duration

A user can therefore move among voicings without losing the intended part assignments.

## 2. User goals

The plugin must support these core arranging jobs:

1. Build a progression quickly from diatonic chords in a selected key.
2. Select any progression chord and assign Root, 3rd, 5th, 7th, or another available chord member to each part.
3. Place every part in an exact octave.
4. move one part to the next or previous available chord tone.
5. Rotate chord-member assignments among all four parts.
6. Generate close, spread, or smoothly voice-led voicings.
7. Hear the current four-part voicing before inserting it.
8. Insert one chord or the complete progression at a selected score beat.
9. Read an existing vertical score chord back into the editor.
10. See the selected voicing on treble-clef T1/T2/Baritone staves and a bass-clef Bass staff.

## 3. Scope

### 3.1 Included in version 1.0

- Major, natural-minor, and harmonic-minor diatonic palettes
- Triad and seventh-chord palette modes
- Sharp or flat display preference
- Supported custom qualities:
  - Major
  - Minor
  - Diminished
  - Augmented
  - Dominant seventh
  - Major seventh
  - Minor seventh
  - Half-diminished seventh
  - Diminished seventh
  - Minor-major seventh
  - Augmented-major seventh
  - Sus2
  - Sus4
- Internal drag-and-drop from the chord palette to the progression
- Internal progression reordering by drag or arrow buttons
- Per-chord duration
- Per-part chord-member and octave editing
- Per-part next/previous chord-tone movement and octave movement
- Close, spread, and smooth-from-previous voicing generation
- Upward and downward role rotation
- Suggested range, voice-crossing, spacing, and missing-tone warnings
- Staff mapping
- Selected-score-chord analysis
- Single-chord insertion
- Full-progression insertion
- Temporary score-based audio preview
- Live four-staff pitch preview with accidentals and ledger lines
- Responsive single-page layout with vertical scrolling
- Advanced controls collapsed by default
- One undo group for each insertion operation

### 3.2 Deliberate non-goals for version 1.0

- Native palette-style dropping directly onto arbitrary page coordinates in the MuseScore notation canvas
- Saving progression projects between plugin sessions
- Writing chord symbols, lyrics, dynamics, or articulations
- Automatic melody locking
- Automatic bass-line generation
- Microtonal chords
- More than four vocal parts
- Multiple simultaneous notes on one vocal staff
- A stand-alone synthesizer independent of the MuseScore score

## 4. Interaction model

### 4.1 Page structure

The dialog uses one vertically scrollable page in this order:

```text
Harmony → Palette → Progression → Voicing + staff preview → Insert → Advanced
```

Voicing controls and staff preview sit side by side at wide widths. They stack vertically below 860 pixels. The Advanced panel starts collapsed.

### 4.2 Global setup

The Harmony panel provides:

- Key selector
- Mode selector
- Triad/seventh toggle
- Sharp/flat preference in Advanced

Changing the key transposes all existing progression chord roots and keeps each part near its transposed register. Changing mode or the seventh toggle rebuilds the palette but does not replace existing custom progression chords.

### 4.3 Chord palette

Seven diatonic chord cards are displayed for the selected key and mode. Each card shows:

- Roman numeral
- Chord symbol

A card can be clicked to append it or dragged to a location in the progression lane. Advanced contains a button for adding a freely editable custom chord.

### 4.4 Progression lane

Each vertical progression card displays:

- Roman numeral or source label
- Chord symbol
- Duration

Clicking a card selects it. A selected card can be dragged, moved with left/right buttons, duplicated, or deleted.

### 4.5 Chord editor

For the selected chord, the user can change:

- Root
- Quality
- Duration
- Chord member for every part
- Octave for every part

Advanced provides per-part controls for:

- One octave down
- Previous available chord tone
- Next available chord tone
- One octave up

The displayed pitch is the exact resulting MIDI-style note name, such as `E3`, `B3`, or `G4`.

### 4.6 Live staff preview

The selected chord is drawn on four separate staves. T1, T2, and Baritone use treble clefs. Bass uses a bass clef. Each edit immediately updates note position, stem, accidental, ledger lines, and pitch label. Notes outside suggested part ranges use a warning color.

The preview is a compact pitch display, not a replacement for MuseScore's engraving engine.

### 4.7 Voicing actions

**Smooth from previous** minimizes motion from the preceding progression chord while preserving ranges, chord completeness, and normal part order where possible.

**Close** favors a compact upper-three-part span.

**Spread** favors a wider upper-three-part span.

**Rotate roles** moves the chord-member assignments among Bass, Baritone, T2, and T1 while keeping every singer near the singer's previous register. Rotation is intentionally allowed to create a crossing or range warning; the arranger remains in control.

### 4.8 Score connection

The default mapping uses the bottom four score staves in this order:

1. Tenor 1
2. Tenor 2
3. Baritone
4. Bass

Each part can instead be mapped to any distinct staff number in the open score.

To insert, the user selects a note, rest, chord, or range start in MuseScore. The plugin uses that tick as the insertion point and writes voice 1 on each mapped staff.

### 4.9 Existing-chord analysis

The user selects a score beat and a destination progression card, then chooses **Analyze notes at score selection**. The plugin:

1. Reads one note from each mapped staff at that tick.
2. Compares the four pitch classes with every supported root/quality combination.
3. Chooses the best complete or subset-compatible chord interpretation, favoring a bass root when otherwise tied.
4. Loads the detected root, quality, exact chord-member assignment, and octave into the selected progression card.

## 5. Data model

Each progression item is stored in a QML `ListModel` with scalar roles so changes notify the interface reliably.

```text
uid
roman
rootPc
qualityId
durationIndex
bassTone, bassOctave
bariTone, bariOctave
t2Tone, t2Octave
t1Tone, t1Octave
```

`rootPc` is an integer from 0 through 11. A `Tone` value is an index into the selected quality's interval list. An `Octave` value uses scientific pitch notation, where MIDI 60 is C4.

Example:

```text
Chord: G7
Bass: Root, octave 2       -> G2
Baritone: 5th, octave 3    -> D3
Tenor 2: 3rd, octave 4     -> B4
Tenor 1: flat 7th, octave 4 -> F4
```

The editor warns about the crossing in this example because T2 is above T1.

## 6. Suggested part ranges

Ranges are warning thresholds, not hard constraints:

| Part | Suggested range | MIDI |
|---|---:|---:|
| Bass | E2–C4 | 40–60 |
| Baritone | A2–G4 | 45–67 |
| Tenor 2 | C3–B4 | 48–71 |
| Tenor 1 | G3–E5 | 55–76 |

These defaults are intentionally conservative and should be changed in the source for a specific group's singers when necessary.

## 7. Voicing algorithm

For automatic voicing, the plugin generates every chord-tone candidate inside each part's suggested range. It searches combinations in Bass–Baritone–T2–T1 order and rejects combinations that:

- Cross adjacent parts
- Omit any chord member

It then minimizes a weighted cost made from:

- Distance from previous pitches or default target registers
- Bass-root preference
- Overly wide adjacent upper-part spacing
- Overly wide Bass–Baritone spacing
- Unisons
- Style-specific close or spread targets

For a triad, one member is doubled. For a four-note seventh chord, all four members are normally represented once.

## 8. Score-writing behavior

### 8.1 Single chord

The selected chord is inserted at the selected score tick for its stored duration.

### 8.2 Full progression

All progression cards are inserted consecutively from the selected score tick. The tick advances by each card's duration. If the score is too short, measures are appended automatically.

### 8.3 Undo and safety

A single-chord insert is one MuseScore undo step. A complete-progression insert is also one undo step.

The plugin writes voice 1. MuseScore's current note-entry behavior determines how existing material at the target location is replaced, split, or combined. The user should test on a copy or save before inserting into occupied music.

## 9. Preview design

The public QML plugin interface does not provide a simple arbitrary four-note MIDI-audition function. Version 1.0 therefore uses this score-based preview sequence:

1. Remember the current selection.
2. Add one temporary measure at the score end.
3. Insert a quarter-note version of the selected voicing on the mapped staves.
4. Select and play that range through MuseScore's playback engine.
5. Stop after approximately 1.7 seconds.
6. Execute Undo to remove the temporary measure.
7. Restore the previous selection as closely as the plugin API permits.

The dialog prevents insertion actions while preview is active. The user can stop preview manually.

## 10. Error handling

The status strip reports:

- No open score
- Fewer than four staves
- Invalid or duplicate staff mappings
- No selected progression chord
- No usable score selection
- Missing score notes during analysis
- Unsupported analyzed chord
- Failed score insertion or preview
- Automatic-voicing failure

Score modifications are enclosed in MuseScore command groups. An exception during insertion attempts a rollback.

## 11. Compatibility and constraints

The plugin imports `MuseScore 3.0` because MuseScore Studio 4's current QML plugin registration and bundled plugins continue to expose that import version. The plugin itself targets MuseScore Studio 4.x and uses current score-cursor and command APIs.

The public plugin API does not expose the notation canvas as a palette-compatible drop target with page coordinates. Consequently, drag-and-drop is implemented inside the plugin, followed by explicit insertion at the selected score beat.

## 12. Acceptance criteria

Version 1.0 is functionally complete when all of the following hold:

1. Every key and supported mode produces seven correct diatonic palette chords.
2. Clicking a palette card appends a complete four-part chord.
3. Dragging a palette card can place it in the progression.
4. Progression cards can be selected, reordered, duplicated, and deleted.
5. Every part can be assigned any member of the selected chord.
6. Every part can be assigned an exact octave.
7. Next/previous tone and octave controls update the displayed pitch.
8. Role rotation changes who sings Root, 3rd, 5th, and 7th.
9. Close, spread, and smooth voicings contain every chord member and avoid crossing when a valid in-range solution exists.
10. Range, crossing, spacing, and missing-member warnings update immediately.
11. A valid four-staff score chord can be analyzed into the editor.
12. One chord inserts at the selected score tick.
13. A progression inserts consecutively with per-chord durations.
14. Each insert operation is one undo step.
15. Preview plays the mapped four-part voicing and removes its temporary measure.
16. Main page resizes without horizontal page scrolling and stacks voicing/preview when narrow.
17. Advanced controls start collapsed and remain reachable through the vertical page scroll.
18. Staff preview updates all four requested clefs, pitches, accidentals, and ledger lines after each voicing edit.

## 13. Future extensions

Likely next versions can add:

- Lock T1 as melody
- Lock Bass or any common tone
- Masala-specific voicing presets
- Passing and approach chords
- Bass root/fifth/walk patterns
- Progression save/load
- Chord-symbol insertion
- Keyboard shortcuts for voicing movement
- Range profiles per singer
- Optional doublings and omitted fifths
- Tension support for 9ths, 11ths, and 13ths
- A native C++ extension for direct score-canvas interaction and lower-level audition control
