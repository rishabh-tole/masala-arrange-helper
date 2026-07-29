# Validation Record

**Package:** Masala Arrange Helper 1.0.0  
**Date:** 2026-07-17

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

## Package validation

Before release, the ZIP is checked for:

- A top-level `MasalaArrangeHelper` directory
- `MasalaArrangeHelper.qml` inside that directory
- Documentation and license files
- A successful archive integrity test

## Runtime checklist for the first MuseScore launch

MuseScore Studio is not installed in the package build environment, so these checks must be completed in the application:

1. Plugin appears in Manage plugins and can be enabled.
2. Dialog opens without QML console errors.
3. Palette click adds a chord.
4. Palette drag adds a chord at the drop position.
5. Progression drag and arrow buttons reorder cards.
6. Chord-member and octave controls update notes.
7. Close, spread, smooth, and rotate actions update the voicing.
8. A selected rest provides a valid insertion tick.
9. Single-chord insertion writes one note on each mapped staff.
10. Full-progression insertion advances by stored durations.
11. Undo reverses each insert in one step.
12. Score-chord analysis reads four mapped notes.
13. Preview plays and automatically removes its temporary measure.

## Known highest-risk runtime area

Temporary preview crosses three MuseScore subsystems: score editing, selection, and playback. The source uses current playback command URIs and then calls the backward-compatible `undo` action to remove the preview command. If a particular MuseScore build changes command dispatch behavior, normal insertion should remain independent; only preview cleanup may require adjustment.
