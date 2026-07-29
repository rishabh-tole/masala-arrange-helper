# Validation Record

**Package:** Masala Arrange Helper 1.0.0  
**Date:** 2026-07-16

## Completed automated checks

### QML/JavaScript lexical validation

- All braces, brackets, and parentheses are balanced.
- Quoted strings and block comments terminate correctly.
- Seventy-five named JavaScript function declarations were extracted from the QML source.
- The extracted functions passed `node --check` with Node.js 22.16.0.

### Music-logic validation

A mocked QML `ListModel` test harness exercised:

- Major diatonic triad palette generation
- Natural-minor and harmonic-minor palette generation
- Triad and seventh variants
- Key transposition
- Duration-to-tick conversion at a 480-tick quarter-note division
- Chord-member role rotation
- Next-chord-tone movement
- Smooth voicing after a quality change
- Automatic voicing for all 13 supported chord qualities in all 12 roots

The automatic-voicing matrix contained 156 quality/root cases. Every case produced:

- Four notes
- Ascending Bass–Baritone–T2–T1 order
- Notes inside the configured suggested ranges
- Complete representation of every chord member

### UI and staff-preview validation

Eleven Node tests now verify:

- One vertically scrollable page with horizontal scrolling disabled
- Responsive side-by-side/stacked voicing and staff-preview layout
- Advanced controls collapsed by default
- Palette and progression drag-and-drop contracts
- Four preview staves in T1, T2, Baritone, Bass order
- Treble clefs for T1, T2, and Baritone; bass clef for Bass
- MIDI pitch placement relative to each clef's bottom staff line
- Sharp/flat spelling and ledger-line generation
- Balanced QML delimiters and unique QML IDs
- Valid syntax for all 75 named QML JavaScript functions
- Valid staff-preview JavaScript syntax

### MuseScore runtime load

MuseScore Studio 4.6.3 loaded the plugin from its installed plugin directory with no QML parse failure. Live logging exposed one progression-card duration-role binding error after a chord was added. That binding now reads the duration from the delegate's explicit model row and has a regression test.

macOS Assistive Access prevented automated menu and screenshot control, so final visual resize interaction remains a manual check.

## Package validation

Before release, the ZIP is checked for:

- A top-level `MasalaArrangeHelper` directory
- `MasalaArrangeHelper.qml` inside that directory
- Documentation and license files
- A successful archive integrity test

## Runtime checklist for the first MuseScore launch

These interaction checks remain for final in-application sign-off:

1. Plugin appears in Manage plugins and can be enabled.
2. Dialog opens without new QML console errors.
3. Window resizes; narrow layout stacks staff preview below voicing controls.
4. Main page scrolls vertically without horizontal page scrolling.
5. Advanced starts collapsed and expands without moving controls off-screen.
6. Live preview shows T1/T2/Baritone on treble clefs and Bass on bass clef.
7. Changing chord member or octave repaints note, accidental, ledger lines, and pitch label.
8. Palette click adds a chord.
9. Palette drag adds a chord at the drop position.
10. Progression drag and arrow buttons reorder cards.
11. Chord-member and octave controls update notes.
12. Close, spread, smooth, and rotate actions update the voicing.
13. A selected rest provides a valid insertion tick.
14. Single-chord insertion writes one note on each mapped staff.
15. Full-progression insertion advances by stored durations.
16. Undo reverses each insert in one step.
17. Score-chord analysis reads four mapped notes.
18. Preview plays and automatically removes its temporary measure.

## Known highest-risk runtime area

Temporary preview crosses three MuseScore subsystems: score editing, selection, and playback. The source uses current playback command URIs and then calls the backward-compatible `undo` action to remove the preview command. If a particular MuseScore build changes command dispatch behavior, normal insertion should remain independent; only preview cleanup may require adjustment.
