// Masala Arrange Helper for MuseScore Studio 4
// Copyright (C) 2026 OpenAI
// SPDX-License-Identifier: GPL-3.0-only
//
// A four-part vocal voicing workbench for Bass, Baritone, Tenor 2, and Tenor 1.
// This plugin is free software: you may redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, version 3.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import MuseScore 3.0

MuseScore {
    id: root

    version: "1.0.0"
    title: "Masala Arrange Helper"
    description: "Build, audition, revoice, and insert four-part Masala-style vocal chords."
    pluginType: "dialog"
    requiresScore: true
    categoryCode: "composing-arranging-tools"

    width: 1180
    height: 820

    // ---------- Runtime state ----------

    property int selectedChordIndex: -1
    property int nextUid: 1
    property int uiRevision: 0

    property int currentKeyPc: 0
    property string currentModeId: "major"
    property bool useSevenths: false
    property bool preferFlats: false
    property int defaultDurationIndex: 2

    // Default staff order: T1, T2, Baritone, Bass.
    property int t1StaffNumber: 1
    property int t2StaffNumber: 2
    property int bariStaffNumber: 3
    property int bassStaffNumber: 4

    property string statusMessage: "Choose a key, add chords, then select a beat in the score."
    property bool statusIsError: false

    property bool previewActive: false
    property int previewOriginalEndTick: -1
    property var savedSelection: null

    // ---------- Musical definitions ----------

    property var sharpNames: ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    property var flatNames:  ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    property var qualityDefinitions: ({
        "maj":       { name: "Major",                  suffix: "",          intervals: [0, 4, 7] },
        "min":       { name: "Minor",                  suffix: "m",         intervals: [0, 3, 7] },
        "dim":       { name: "Diminished",             suffix: "°",         intervals: [0, 3, 6] },
        "aug":       { name: "Augmented",              suffix: "+",         intervals: [0, 4, 8] },
        "dom7":      { name: "Dominant seventh",       suffix: "7",         intervals: [0, 4, 7, 10] },
        "maj7":      { name: "Major seventh",          suffix: "maj7",      intervals: [0, 4, 7, 11] },
        "min7":      { name: "Minor seventh",          suffix: "m7",        intervals: [0, 3, 7, 10] },
        "hdim7":     { name: "Half-diminished seventh",suffix: "ø7",        intervals: [0, 3, 6, 10] },
        "dim7":      { name: "Diminished seventh",     suffix: "°7",        intervals: [0, 3, 6, 9] },
        "minMaj7":   { name: "Minor-major seventh",    suffix: "m(maj7)",   intervals: [0, 3, 7, 11] },
        "augMaj7":   { name: "Augmented-major seventh",suffix: "+maj7",     intervals: [0, 4, 8, 11] },
        "sus2":      { name: "Suspended second",       suffix: "sus2",      intervals: [0, 2, 7] },
        "sus4":      { name: "Suspended fourth",       suffix: "sus4",      intervals: [0, 5, 7] }
    })

    property var qualityChoices: [
        { id: "maj",     text: "Major" },
        { id: "min",     text: "Minor" },
        { id: "dim",     text: "Diminished" },
        { id: "aug",     text: "Augmented" },
        { id: "dom7",    text: "Dominant 7" },
        { id: "maj7",    text: "Major 7" },
        { id: "min7",    text: "Minor 7" },
        { id: "hdim7",   text: "Half-diminished 7" },
        { id: "dim7",    text: "Diminished 7" },
        { id: "minMaj7", text: "Minor-major 7" },
        { id: "augMaj7", text: "Augmented-major 7" },
        { id: "sus2",    text: "Sus2" },
        { id: "sus4",    text: "Sus4" }
    ]

    property var modeDefinitions: ({
        "major": {
            name: "Major",
            scale: [0, 2, 4, 5, 7, 9, 11],
            romans3: ["I", "ii", "iii", "IV", "V", "vi", "vii°"],
            qualities3: ["maj", "min", "min", "maj", "maj", "min", "dim"],
            romans7: ["Imaj7", "ii7", "iii7", "IVmaj7", "V7", "vi7", "viiø7"],
            qualities7: ["maj7", "min7", "min7", "maj7", "dom7", "min7", "hdim7"]
        },
        "naturalMinor": {
            name: "Natural minor",
            scale: [0, 2, 3, 5, 7, 8, 10],
            romans3: ["i", "ii°", "III", "iv", "v", "VI", "VII"],
            qualities3: ["min", "dim", "maj", "min", "min", "maj", "maj"],
            romans7: ["i7", "iiø7", "IIImaj7", "iv7", "v7", "VImaj7", "VII7"],
            qualities7: ["min7", "hdim7", "maj7", "min7", "min7", "maj7", "dom7"]
        },
        "harmonicMinor": {
            name: "Harmonic minor",
            scale: [0, 2, 3, 5, 7, 8, 11],
            romans3: ["i", "ii°", "III+", "iv", "V", "VI", "vii°"],
            qualities3: ["min", "dim", "aug", "min", "maj", "maj", "dim"],
            romans7: ["i(maj7)", "iiø7", "III+maj7", "iv7", "V7", "VImaj7", "vii°7"],
            qualities7: ["minMaj7", "hdim7", "augMaj7", "min7", "dom7", "maj7", "dim7"]
        }
    })

    property var durationDefinitions: [
        { text: "Whole",          num: 1, den: 1 },
        { text: "Dotted half",    num: 3, den: 4 },
        { text: "Half",           num: 1, den: 2 },
        { text: "Dotted quarter", num: 3, den: 8 },
        { text: "Quarter",        num: 1, den: 4 },
        { text: "Eighth",         num: 1, den: 8 }
    ]

    // MIDI ranges are warnings, not hard limits.
    property var voiceDefinitions: [
        { id: "bass", label: "Bass",      shortLabel: "B",  min: 40, max: 60, target: 43 }, // E2-C4
        { id: "bari", label: "Baritone",  shortLabel: "Bar",min: 45, max: 67, target: 55 }, // A2-G4
        { id: "t2",   label: "Tenor 2",   shortLabel: "T2", min: 48, max: 71, target: 62 }, // C3-B4
        { id: "t1",   label: "Tenor 1",   shortLabel: "T1", min: 55, max: 76, target: 67 }  // G3-E5
    ]

    ListModel { id: paletteModel }
    ListModel { id: progressionModel }

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    Timer {
        id: previewTimer
        interval: 1700
        repeat: false
        onTriggered: root.finishPreview("Preview finished.")
    }

    // ---------- General helpers ----------

    function touchUi() {
        uiRevision += 1
    }

    function setStatus(message, isError) {
        statusMessage = message
        statusIsError = !!isError
    }

    function mod(value, modulus) {
        return ((value % modulus) + modulus) % modulus
    }

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function noteNames() {
        var ignored = uiRevision
        return preferFlats ? flatNames : sharpNames
    }

    function noteNameFromPc(pc) {
        return noteNames()[mod(pc, 12)]
    }

    function midiNoteName(pitch) {
        if (pitch < 0 || pitch > 127)
            return "—"
        var octave = Math.floor(pitch / 12) - 1
        return noteNameFromPc(pitch) + octave
    }

    function qualityDefinition(qualityId) {
        return qualityDefinitions[qualityId] || qualityDefinitions["maj"]
    }

    function qualityIndex(qualityId) {
        for (var i = 0; i < qualityChoices.length; ++i) {
            if (qualityChoices[i].id === qualityId)
                return i
        }
        return 0
    }

    function qualitySuffix(qualityId) {
        return qualityDefinition(qualityId).suffix
    }

    function chordSymbol(chord) {
        if (!chord)
            return "—"
        return noteNameFromPc(chord.rootPc) + qualitySuffix(chord.qualityId)
    }

    function intervalLabel(interval) {
        switch (mod(interval, 12)) {
        case 0:  return "Root"
        case 1:  return "♭2 / ♭9"
        case 2:  return "2nd / 9th"
        case 3:  return "♭3rd"
        case 4:  return "3rd"
        case 5:  return "4th / 11th"
        case 6:  return "♭5th / ♯11"
        case 7:  return "5th"
        case 8:  return "♯5th / ♭13"
        case 9:  return "6th / dim7"
        case 10: return "♭7th"
        case 11: return "7th"
        }
        return "Tone"
    }

    function selectedChord() {
        var ignored = uiRevision
        if (selectedChordIndex < 0 || selectedChordIndex >= progressionModel.count)
            return null
        return progressionModel.get(selectedChordIndex)
    }

    function chordAt(index) {
        if (index < 0 || index >= progressionModel.count)
            return null
        return progressionModel.get(index)
    }

    function toneOptionsForChord(chord) {
        var options = []
        if (!chord)
            return options
        var intervals = qualityDefinition(chord.qualityId).intervals
        for (var i = 0; i < intervals.length; ++i) {
            options.push(intervalLabel(intervals[i]) + "  ·  " + noteNameFromPc(chord.rootPc + intervals[i]))
        }
        return options
    }

    function toneOptionsForSelected() {
        var ignored = uiRevision
        return toneOptionsForChord(selectedChord())
    }

    function voiceToneRole(voiceId) {
        return voiceId + "Tone"
    }

    function voiceOctaveRole(voiceId) {
        return voiceId + "Octave"
    }

    function getVoiceTone(chord, voiceId) {
        var ignored = uiRevision
        if (!chord)
            return 0
        var value = chord[voiceToneRole(voiceId)]
        return value === undefined ? 0 : value
    }

    function getVoiceOctave(chord, voiceId) {
        var ignored = uiRevision
        if (!chord)
            return 3
        var value = chord[voiceOctaveRole(voiceId)]
        return value === undefined ? 3 : value
    }

    function voicePitch(chord, voiceId) {
        if (!chord)
            return -1
        var intervals = qualityDefinition(chord.qualityId).intervals
        var toneIndex = clamp(getVoiceTone(chord, voiceId), 0, intervals.length - 1)
        var octave = getVoiceOctave(chord, voiceId)
        var pitchClass = mod(chord.rootPc + intervals[toneIndex], 12)
        return (octave + 1) * 12 + pitchClass
    }

    function selectedVoicePitch(voiceId) {
        var ignored = uiRevision
        return voicePitch(selectedChord(), voiceId)
    }

    function setChordProperty(index, role, value) {
        if (index < 0 || index >= progressionModel.count)
            return
        progressionModel.setProperty(index, role, value)
        touchUi()
    }

    function setSelectedChordProperty(role, value) {
        setChordProperty(selectedChordIndex, role, value)
    }

    function setVoicePitch(index, voiceId, pitch) {
        var chord = chordAt(index)
        if (!chord)
            return false
        var intervals = qualityDefinition(chord.qualityId).intervals
        var intervalFromRoot = mod(pitch - chord.rootPc, 12)
        var toneIndex = -1
        for (var i = 0; i < intervals.length; ++i) {
            if (mod(intervals[i], 12) === intervalFromRoot) {
                toneIndex = i
                break
            }
        }
        if (toneIndex < 0)
            return false
        progressionModel.setProperty(index, voiceToneRole(voiceId), toneIndex)
        progressionModel.setProperty(index, voiceOctaveRole(voiceId), Math.floor(pitch / 12) - 1)
        touchUi()
        return true
    }

    function nearestPitchForTone(chord, toneIndex, targetPitch) {
        var intervals = qualityDefinition(chord.qualityId).intervals
        toneIndex = clamp(toneIndex, 0, intervals.length - 1)
        var pc = mod(chord.rootPc + intervals[toneIndex], 12)
        var targetOctave = Math.floor(targetPitch / 12) - 1
        var bestPitch = (targetOctave + 1) * 12 + pc
        var bestDistance = Math.abs(bestPitch - targetPitch)
        for (var octave = targetOctave - 2; octave <= targetOctave + 2; ++octave) {
            var pitch = (octave + 1) * 12 + pc
            var distance = Math.abs(pitch - targetPitch)
            if (distance < bestDistance) {
                bestPitch = pitch
                bestDistance = distance
            }
        }
        return bestPitch
    }

    function setVoiceToneKeepingRegister(index, voiceId, toneIndex) {
        var chord = chordAt(index)
        if (!chord)
            return
        var oldPitch = voicePitch(chord, voiceId)
        var intervals = qualityDefinition(chord.qualityId).intervals
        toneIndex = clamp(toneIndex, 0, intervals.length - 1)
        var newPitch = nearestPitchForTone(chord, toneIndex, oldPitch)
        progressionModel.setProperty(index, voiceToneRole(voiceId), toneIndex)
        progressionModel.setProperty(index, voiceOctaveRole(voiceId), Math.floor(newPitch / 12) - 1)
        touchUi()
    }

    function setSelectedVoiceTone(voiceId, toneIndex) {
        setVoiceToneKeepingRegister(selectedChordIndex, voiceId, toneIndex)
    }

    function setSelectedVoiceOctave(voiceId, octave) {
        setChordProperty(selectedChordIndex, voiceOctaveRole(voiceId), octave)
    }

    function candidatePitchesForChord(chord, minimum, maximum) {
        var result = []
        var intervals = qualityDefinition(chord.qualityId).intervals
        for (var pitch = minimum; pitch <= maximum; ++pitch) {
            var relative = mod(pitch - chord.rootPc, 12)
            for (var i = 0; i < intervals.length; ++i) {
                if (mod(intervals[i], 12) === relative) {
                    result.push(pitch)
                    break
                }
            }
        }
        return result
    }

    function stepSelectedVoice(voiceId, direction) {
        var chord = selectedChord()
        if (!chord)
            return
        var currentPitch = voicePitch(chord, voiceId)
        var candidates = candidatePitchesForChord(chord, 24, 96)
        if (direction > 0) {
            for (var i = 0; i < candidates.length; ++i) {
                if (candidates[i] > currentPitch) {
                    setVoicePitch(selectedChordIndex, voiceId, candidates[i])
                    return
                }
            }
        } else {
            for (var j = candidates.length - 1; j >= 0; --j) {
                if (candidates[j] < currentPitch) {
                    setVoicePitch(selectedChordIndex, voiceId, candidates[j])
                    return
                }
            }
        }
    }

    function shiftSelectedVoiceOctave(voiceId, delta) {
        var chord = selectedChord()
        if (!chord)
            return
        setSelectedVoiceOctave(voiceId, getVoiceOctave(chord, voiceId) + delta)
    }

    function voiceDefinition(voiceId) {
        for (var i = 0; i < voiceDefinitions.length; ++i) {
            if (voiceDefinitions[i].id === voiceId)
                return voiceDefinitions[i]
        }
        return voiceDefinitions[0]
    }

    // ---------- Palette and progression ----------

    function rebuildPalette() {
        paletteModel.clear()
        var mode = modeDefinitions[currentModeId]
        var romans = useSevenths ? mode.romans7 : mode.romans3
        var qualities = useSevenths ? mode.qualities7 : mode.qualities3
        for (var i = 0; i < 7; ++i) {
            paletteModel.append({
                degree: i,
                roman: romans[i],
                rootPc: mod(currentKeyPc + mode.scale[i], 12),
                qualityId: qualities[i]
            })
        }
        touchUi()
    }

    function defaultChordObject(rootPc, qualityId, roman, durationIndex) {
        var intervals = qualityDefinition(qualityId).intervals
        var topTone = intervals.length >= 4 ? 3 : 0
        return {
            uid: nextUid++,
            roman: roman || "Custom",
            rootPc: mod(rootPc, 12),
            qualityId: qualityId,
            durationIndex: durationIndex,
            bassTone: 0,
            bassOctave: 2,
            bariTone: Math.min(2, intervals.length - 1),
            bariOctave: 3,
            t2Tone: Math.min(1, intervals.length - 1),
            t2Octave: 4,
            t1Tone: topTone,
            t1Octave: 4
        }
    }

    function addPaletteChord(paletteIndex, insertIndex) {
        if (paletteIndex < 0 || paletteIndex >= paletteModel.count)
            return
        var source = paletteModel.get(paletteIndex)
        var chord = defaultChordObject(source.rootPc, source.qualityId, source.roman, defaultDurationIndex)
        if (insertIndex === undefined || insertIndex < 0 || insertIndex > progressionModel.count)
            insertIndex = progressionModel.count
        progressionModel.insert(insertIndex, chord)
        selectedChordIndex = insertIndex
        optimizeChord(insertIndex, insertIndex > 0 ? "smooth" : "close")
        setStatus("Added " + chordSymbol(progressionModel.get(insertIndex)) + ".", false)
        touchUi()
    }

    function addCustomChord() {
        var chord = defaultChordObject(currentKeyPc, useSevenths ? "maj7" : "maj", "Custom", defaultDurationIndex)
        progressionModel.append(chord)
        selectedChordIndex = progressionModel.count - 1
        optimizeChord(selectedChordIndex, selectedChordIndex > 0 ? "smooth" : "close")
        setStatus("Added a custom chord.", false)
        touchUi()
    }

    function duplicateSelectedChord() {
        var chord = selectedChord()
        if (!chord)
            return
        var copy = {
            uid: nextUid++,
            roman: chord.roman,
            rootPc: chord.rootPc,
            qualityId: chord.qualityId,
            durationIndex: chord.durationIndex,
            bassTone: chord.bassTone,
            bassOctave: chord.bassOctave,
            bariTone: chord.bariTone,
            bariOctave: chord.bariOctave,
            t2Tone: chord.t2Tone,
            t2Octave: chord.t2Octave,
            t1Tone: chord.t1Tone,
            t1Octave: chord.t1Octave
        }
        progressionModel.insert(selectedChordIndex + 1, copy)
        selectedChordIndex += 1
        touchUi()
    }

    function deleteSelectedChord() {
        if (selectedChordIndex < 0 || selectedChordIndex >= progressionModel.count)
            return
        progressionModel.remove(selectedChordIndex)
        if (progressionModel.count === 0)
            selectedChordIndex = -1
        else
            selectedChordIndex = Math.min(selectedChordIndex, progressionModel.count - 1)
        touchUi()
    }

    function clearProgression() {
        progressionModel.clear()
        selectedChordIndex = -1
        setStatus("Progression cleared.", false)
        touchUi()
    }

    function indexForUid(uid) {
        for (var i = 0; i < progressionModel.count; ++i) {
            if (progressionModel.get(i).uid === uid)
                return i
        }
        return -1
    }

    function moveChord(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= progressionModel.count)
            return
        toIndex = clamp(toIndex, 0, progressionModel.count - 1)
        if (fromIndex === toIndex)
            return
        var selectedUid = selectedChord() ? selectedChord().uid : -1
        progressionModel.move(fromIndex, toIndex, 1)
        selectedChordIndex = indexForUid(selectedUid)
        touchUi()
    }

    function moveSelected(delta) {
        if (selectedChordIndex < 0)
            return
        moveChord(selectedChordIndex, selectedChordIndex + delta)
    }

    function changeKey(newKeyPc) {
        newKeyPc = mod(newKeyPc, 12)
        var delta = mod(newKeyPc - currentKeyPc, 12)
        if (delta > 6)
            delta -= 12
        if (delta !== 0) {
            for (var i = 0; i < progressionModel.count; ++i) {
                var chord = progressionModel.get(i)
                var pitches = {}
                for (var v = 0; v < voiceDefinitions.length; ++v) {
                    var voiceId = voiceDefinitions[v].id
                    pitches[voiceId] = voicePitch(chord, voiceId) + delta
                }
                progressionModel.setProperty(i, "rootPc", mod(chord.rootPc + delta, 12))
                for (var w = 0; w < voiceDefinitions.length; ++w) {
                    var voiceId2 = voiceDefinitions[w].id
                    var updated = progressionModel.get(i)
                    var tone = getVoiceTone(updated, voiceId2)
                    var nearest = nearestPitchForTone(updated, tone, pitches[voiceId2])
                    progressionModel.setProperty(i, voiceOctaveRole(voiceId2), Math.floor(nearest / 12) - 1)
                }
            }
        }
        currentKeyPc = newKeyPc
        rebuildPalette()
        setStatus("Key changed to " + noteNameFromPc(currentKeyPc) + "; the progression was transposed with it.", false)
        touchUi()
    }

    function changeSelectedRoot(newRootPc) {
        var chord = selectedChord()
        if (!chord)
            return
        var oldPitches = {}
        for (var i = 0; i < voiceDefinitions.length; ++i) {
            var voiceId = voiceDefinitions[i].id
            oldPitches[voiceId] = voicePitch(chord, voiceId)
        }
        progressionModel.setProperty(selectedChordIndex, "rootPc", mod(newRootPc, 12))
        var updated = selectedChord()
        for (var j = 0; j < voiceDefinitions.length; ++j) {
            var voiceId2 = voiceDefinitions[j].id
            var tone = getVoiceTone(updated, voiceId2)
            var nearest = nearestPitchForTone(updated, tone, oldPitches[voiceId2])
            progressionModel.setProperty(selectedChordIndex, voiceOctaveRole(voiceId2), Math.floor(nearest / 12) - 1)
        }
        progressionModel.setProperty(selectedChordIndex, "roman", "Custom")
        touchUi()
    }

    function changeSelectedQuality(newQualityId) {
        var chord = selectedChord()
        if (!chord || !qualityDefinitions[newQualityId])
            return
        var oldPitches = {}
        for (var i = 0; i < voiceDefinitions.length; ++i) {
            var voiceId = voiceDefinitions[i].id
            oldPitches[voiceId] = voicePitch(chord, voiceId)
        }
        progressionModel.setProperty(selectedChordIndex, "qualityId", newQualityId)
        var updated = selectedChord()
        var intervals = qualityDefinition(newQualityId).intervals
        for (var j = 0; j < voiceDefinitions.length; ++j) {
            var voiceId2 = voiceDefinitions[j].id
            var bestTone = 0
            var bestPitch = nearestPitchForTone(updated, 0, oldPitches[voiceId2])
            var bestDistance = Math.abs(bestPitch - oldPitches[voiceId2])
            for (var tone = 1; tone < intervals.length; ++tone) {
                var pitch = nearestPitchForTone(updated, tone, oldPitches[voiceId2])
                var distance = Math.abs(pitch - oldPitches[voiceId2])
                if (distance < bestDistance) {
                    bestTone = tone
                    bestPitch = pitch
                    bestDistance = distance
                }
            }
            progressionModel.setProperty(selectedChordIndex, voiceToneRole(voiceId2), bestTone)
            progressionModel.setProperty(selectedChordIndex, voiceOctaveRole(voiceId2), Math.floor(bestPitch / 12) - 1)
        }
        progressionModel.setProperty(selectedChordIndex, "roman", "Custom")
        touchUi()
    }

    // ---------- Voicing engine ----------

    function allChordTonesPresent(chord, pitches) {
        var intervals = qualityDefinition(chord.qualityId).intervals
        for (var tone = 0; tone < intervals.length; ++tone) {
            var wantedPc = mod(chord.rootPc + intervals[tone], 12)
            var found = false
            for (var i = 0; i < pitches.length; ++i) {
                if (mod(pitches[i], 12) === wantedPc) {
                    found = true
                    break
                }
            }
            if (!found)
                return false
        }
        return true
    }

    function voicingCost(chord, pitches, targets, style) {
        var cost = 0
        for (var i = 0; i < pitches.length; ++i)
            cost += Math.abs(pitches[i] - targets[i])

        // Bass-root preference, but not a hard rule.
        if (mod(pitches[0], 12) !== mod(chord.rootPc, 12))
            cost += 5

        var bassGap = pitches[1] - pitches[0]
        var lowUpperGap = pitches[2] - pitches[1]
        var topGap = pitches[3] - pitches[2]
        if (bassGap > 19)
            cost += (bassGap - 19) * 2
        if (lowUpperGap > 12)
            cost += (lowUpperGap - 12) * 5
        if (topGap > 12)
            cost += (topGap - 12) * 5
        if (bassGap === 0 || lowUpperGap === 0 || topGap === 0)
            cost += 2

        if (style === "close") {
            cost += Math.abs((pitches[3] - pitches[1]) - 10) * 1.4
        } else if (style === "spread") {
            cost += Math.abs((pitches[3] - pitches[1]) - 19) * 1.2
            if (pitches[2] - pitches[1] < 5)
                cost += 5
        }
        return cost
    }

    function optimizeChord(index, style) {
        var chord = chordAt(index)
        if (!chord)
            return

        var targets = []
        if (style === "smooth" && index > 0) {
            var previous = chordAt(index - 1)
            for (var p = 0; p < voiceDefinitions.length; ++p)
                targets.push(voicePitch(previous, voiceDefinitions[p].id))
        } else if (style === "spread") {
            targets = [43, 52, 64, 74]
        } else {
            for (var t = 0; t < voiceDefinitions.length; ++t)
                targets.push(voiceDefinitions[t].target)
        }

        var candidates = []
        for (var v = 0; v < voiceDefinitions.length; ++v) {
            var def = voiceDefinitions[v]
            candidates.push(candidatePitchesForChord(chord, def.min, def.max))
        }

        var best = null
        var bestCost = 1000000000
        for (var b = 0; b < candidates[0].length; ++b) {
            var bass = candidates[0][b]
            for (var a = 0; a < candidates[1].length; ++a) {
                var bari = candidates[1][a]
                if (bari < bass)
                    continue
                for (var u = 0; u < candidates[2].length; ++u) {
                    var t2 = candidates[2][u]
                    if (t2 < bari)
                        continue
                    for (var s = 0; s < candidates[3].length; ++s) {
                        var t1 = candidates[3][s]
                        if (t1 < t2)
                            continue
                        var pitches = [bass, bari, t2, t1]
                        if (!allChordTonesPresent(chord, pitches))
                            continue
                        var cost = voicingCost(chord, pitches, targets, style)
                        if (cost < bestCost) {
                            bestCost = cost
                            best = pitches
                        }
                    }
                }
            }
        }

        if (!best) {
            setStatus("No in-range, uncrossed voicing was found. You can still edit each part manually.", true)
            return
        }

        for (var i = 0; i < voiceDefinitions.length; ++i)
            setVoicePitch(index, voiceDefinitions[i].id, best[i])
        touchUi()
    }

    function optimizeSelected(style) {
        optimizeChord(selectedChordIndex, style)
        if (selectedChord())
            setStatus("Applied " + style + " voicing to " + chordSymbol(selectedChord()) + ".", false)
    }

    function rotateAssignments(direction) {
        var chord = selectedChord()
        if (!chord)
            return
        var ids = ["bass", "bari", "t2", "t1"]
        var oldPitches = []
        var oldTones = []
        for (var i = 0; i < ids.length; ++i) {
            oldPitches.push(voicePitch(chord, ids[i]))
            oldTones.push(getVoiceTone(chord, ids[i]))
        }
        for (var j = 0; j < ids.length; ++j) {
            var sourceIndex = direction > 0 ? mod(j - 1, ids.length) : mod(j + 1, ids.length)
            var newTone = oldTones[sourceIndex]
            var newPitch = nearestPitchForTone(chord, newTone, oldPitches[j])
            progressionModel.setProperty(selectedChordIndex, voiceToneRole(ids[j]), newTone)
            progressionModel.setProperty(selectedChordIndex, voiceOctaveRole(ids[j]), Math.floor(newPitch / 12) - 1)
        }
        touchUi()
        setStatus("Rotated which part sings each chord member.", false)
    }

    function selectedWarnings() {
        var ignored = uiRevision
        var chord = selectedChord()
        if (!chord)
            return "Add or select a chord to edit its voicing."
        var messages = []
        var pitches = []
        var toneSeen = []
        var intervals = qualityDefinition(chord.qualityId).intervals
        for (var t = 0; t < intervals.length; ++t)
            toneSeen.push(false)

        for (var i = 0; i < voiceDefinitions.length; ++i) {
            var def = voiceDefinitions[i]
            var pitch = voicePitch(chord, def.id)
            pitches.push(pitch)
            var tone = getVoiceTone(chord, def.id)
            if (tone >= 0 && tone < toneSeen.length)
                toneSeen[tone] = true
            if (pitch < def.min || pitch > def.max) {
                messages.push(def.label + " " + midiNoteName(pitch) + " is outside the suggested "
                              + midiNoteName(def.min) + "–" + midiNoteName(def.max) + " range.")
            }
        }

        if (pitches[0] > pitches[1])
            messages.push("Bass crosses above Baritone.")
        if (pitches[1] > pitches[2])
            messages.push("Baritone crosses above Tenor 2.")
        if (pitches[2] > pitches[3])
            messages.push("Tenor 2 crosses above Tenor 1.")
        if (pitches[2] - pitches[1] > 12)
            messages.push("Baritone–Tenor 2 spacing is wider than an octave.")
        if (pitches[3] - pitches[2] > 12)
            messages.push("Tenor 2–Tenor 1 spacing is wider than an octave.")

        var missing = []
        for (var m = 0; m < toneSeen.length; ++m) {
            if (!toneSeen[m])
                missing.push(intervalLabel(intervals[m]))
        }
        if (missing.length > 0)
            messages.push("Missing chord member" + (missing.length > 1 ? "s: " : ": ") + missing.join(", ") + ".")

        if (messages.length === 0)
            return "Voicing check: in range, uncrossed, and every chord member is present."
        return messages.join("\n")
    }

    // ---------- MuseScore selection and staff mapping ----------

    function staffNumberForVoice(voiceId) {
        switch (voiceId) {
        case "t1":   return t1StaffNumber
        case "t2":   return t2StaffNumber
        case "bari": return bariStaffNumber
        case "bass": return bassStaffNumber
        }
        return 1
    }

    function setStaffNumberForVoice(voiceId, staffNumber) {
        switch (voiceId) {
        case "t1":   t1StaffNumber = staffNumber; break
        case "t2":   t2StaffNumber = staffNumber; break
        case "bari": bariStaffNumber = staffNumber; break
        case "bass": bassStaffNumber = staffNumber; break
        }
        touchUi()
    }

    function mappedStaffBounds() {
        var values = [t1StaffNumber - 1, t2StaffNumber - 1, bariStaffNumber - 1, bassStaffNumber - 1]
        var minimum = values[0]
        var maximum = values[0]
        for (var i = 1; i < values.length; ++i) {
            minimum = Math.min(minimum, values[i])
            maximum = Math.max(maximum, values[i])
        }
        return { minimum: minimum, maximum: maximum }
    }

    function validateStaffMapping(showMessage) {
        if (!curScore) {
            if (showMessage)
                setStatus("Open a score before inserting or previewing.", true)
            return false
        }
        if (curScore.nstaves < 4) {
            if (showMessage)
                setStatus("This version needs at least four staves: T1, T2, Baritone, and Bass.", true)
            return false
        }
        var numbers = [t1StaffNumber, t2StaffNumber, bariStaffNumber, bassStaffNumber]
        var seen = {}
        for (var i = 0; i < numbers.length; ++i) {
            if (numbers[i] < 1 || numbers[i] > curScore.nstaves) {
                if (showMessage)
                    setStatus("Every mapped staff number must be between 1 and " + curScore.nstaves + ".", true)
                return false
            }
            if (seen[numbers[i]]) {
                if (showMessage)
                    setStatus("Each vocal part must be mapped to a different staff.", true)
                return false
            }
            seen[numbers[i]] = true
        }
        return true
    }

    function elementTick(element) {
        if (!element)
            return -1
        try {
            if (element.tick !== undefined && element.tick >= 0)
                return element.tick
        } catch (ignored1) {}
        try {
            if (element.segment && element.segment.tick !== undefined)
                return element.segment.tick
        } catch (ignored2) {}
        try {
            if (element.parent && element.parent.tick !== undefined)
                return element.parent.tick
        } catch (ignored3) {}
        try {
            if (element.parent && element.parent.parent && element.parent.parent.tick !== undefined)
                return element.parent.parent.tick
        } catch (ignored4) {}
        return -1
    }

    function selectionStartTick(showMessage) {
        if (!curScore)
            return -1
        var selection = curScore.selection
        try {
            if (selection.isRange && selection.startSegment)
                return selection.startSegment.tick
        } catch (ignored1) {}
        try {
            var elements = selection.elements
            if (elements && elements.length > 0) {
                var tick = elementTick(elements[0])
                if (tick >= 0)
                    return tick
            }
        } catch (ignored2) {}
        if (showMessage)
            setStatus("Select a rest, note, chord, or range at the insertion beat, then try again.", true)
        return -1
    }

    function scoreEndTick() {
        if (!curScore || !curScore.lastMeasure)
            return 0
        try {
            // The final measure's last segment is normally its end barline,
            // whose tick is the first writable tick after the measure.
            if (curScore.lastMeasure.lastSegment)
                return curScore.lastMeasure.lastSegment.tick
        } catch (ignored1) {}
        try {
            if (curScore.lastSegment)
                return curScore.lastSegment.tick
        } catch (ignored2) {}
        return 0
    }

    function ensureScoreLength(requiredEndTick) {
        var guard = 0
        while (scoreEndTick() < requiredEndTick && guard < 256) {
            curScore.appendMeasures(1)
            guard += 1
        }
        if (scoreEndTick() < requiredEndTick)
            throw new Error("Could not append enough measures for the requested progression.")
    }

    function durationAt(index) {
        index = clamp(index, 0, durationDefinitions.length - 1)
        return durationDefinitions[index]
    }

    function durationTicks(index) {
        var duration = durationAt(index)
        return Math.round(division * 4 * duration.num / duration.den)
    }

    function insertChordAtTick(chord, tick, durationIndex) {
        var duration = durationAt(durationIndex)
        for (var i = 0; i < voiceDefinitions.length; ++i) {
            var voiceId = voiceDefinitions[i].id
            var cursor = curScore.newCursor()
            cursor.track = (staffNumberForVoice(voiceId) - 1) * 4
            cursor.rewindToTick(tick)
            cursor.setDuration(duration.num, duration.den)
            cursor.addNote(voicePitch(chord, voiceId))
        }
    }

    function selectInsertedRange(startTick, endTick) {
        var bounds = mappedStaffBounds()
        curScore.selection.selectRange(startTick, endTick, bounds.minimum, bounds.maximum + 1)
    }

    function insertSelectedIntoScore() {
        var chord = selectedChord()
        if (!chord) {
            setStatus("Add or select a chord first.", true)
            return
        }
        if (!validateStaffMapping(true))
            return
        var startTick = selectionStartTick(true)
        if (startTick < 0)
            return
        var endTick = startTick + durationTicks(chord.durationIndex)
        try {
            curScore.startCmd()
            ensureScoreLength(endTick)
            insertChordAtTick(chord, startTick, chord.durationIndex)
            curScore.endCmd()
            selectInsertedRange(startTick, endTick)
            cmd("command://playback/reload-playback-cache")
            setStatus("Inserted " + chordSymbol(chord) + " as one undoable score edit.", false)
        } catch (error) {
            try { curScore.endCmd(true) } catch (ignored) {}
            setStatus("Insert failed: " + error, true)
        }
    }

    function insertProgressionIntoScore() {
        if (progressionModel.count === 0) {
            setStatus("Add at least one chord to the progression first.", true)
            return
        }
        if (!validateStaffMapping(true))
            return
        var startTick = selectionStartTick(true)
        if (startTick < 0)
            return
        var endTick = startTick
        for (var i = 0; i < progressionModel.count; ++i)
            endTick += durationTicks(progressionModel.get(i).durationIndex)
        try {
            curScore.startCmd()
            ensureScoreLength(endTick)
            var tick = startTick
            for (var j = 0; j < progressionModel.count; ++j) {
                var chord = progressionModel.get(j)
                insertChordAtTick(chord, tick, chord.durationIndex)
                tick += durationTicks(chord.durationIndex)
            }
            curScore.endCmd()
            selectInsertedRange(startTick, endTick)
            cmd("command://playback/reload-playback-cache")
            setStatus("Inserted " + progressionModel.count + " chords as one undoable score edit.", false)
        } catch (error) {
            try { curScore.endCmd(true) } catch (ignored) {}
            setStatus("Progression insert failed: " + error, true)
        }
    }

    function pitchAtMappedStaff(voiceId, tick) {
        var cursor = curScore.newCursor()
        cursor.track = (staffNumberForVoice(voiceId) - 1) * 4
        cursor.rewindToTick(tick)
        if (!cursor.segment || cursor.tick !== tick || !cursor.element)
            return -1
        var element = cursor.element
        if (element.type === Element.CHORD && element.notes && element.notes.length > 0)
            return element.notes[0].pitch
        if (element.type === Element.NOTE)
            return element.pitch
        return -1
    }

    function uniquePitchClasses(pitches) {
        var result = []
        var seen = {}
        for (var i = 0; i < pitches.length; ++i) {
            var pc = mod(pitches[i], 12)
            if (!seen[pc]) {
                seen[pc] = true
                result.push(pc)
            }
        }
        return result
    }

    function qualityPitchClasses(rootPc, qualityId) {
        var intervals = qualityDefinition(qualityId).intervals
        var result = []
        for (var i = 0; i < intervals.length; ++i)
            result.push(mod(rootPc + intervals[i], 12))
        return result
    }

    function arrayContains(array, value) {
        for (var i = 0; i < array.length; ++i) {
            if (array[i] === value)
                return true
        }
        return false
    }

    function analyzeSelectedScoreChord() {
        if (!selectedChord()) {
            setStatus("Add or select a progression card to receive the analyzed voicing.", true)
            return
        }
        if (!validateStaffMapping(true))
            return
        var tick = selectionStartTick(true)
        if (tick < 0)
            return
        var ids = ["bass", "bari", "t2", "t1"]
        var pitches = []
        for (var i = 0; i < ids.length; ++i) {
            var pitch = pitchAtMappedStaff(ids[i], tick)
            if (pitch < 0) {
                setStatus("No note was found on the mapped " + voiceDefinition(ids[i]).label + " staff at that beat.", true)
                return
            }
            pitches.push(pitch)
        }

        var unique = uniquePitchClasses(pitches)
        var best = null
        var bestScore = 100000
        for (var rootPc = 0; rootPc < 12; ++rootPc) {
            for (var q = 0; q < qualityChoices.length; ++q) {
                var qualityId = qualityChoices[q].id
                var chordPcs = qualityPitchClasses(rootPc, qualityId)
                var extras = 0
                for (var u = 0; u < unique.length; ++u) {
                    if (!arrayContains(chordPcs, unique[u]))
                        extras += 1
                }
                if (extras > 0)
                    continue
                var missing = 0
                for (var c = 0; c < chordPcs.length; ++c) {
                    if (!arrayContains(unique, chordPcs[c]))
                        missing += 1
                }
                var score = missing * 12 + Math.abs(chordPcs.length - unique.length) * 3
                if (mod(pitches[0], 12) !== rootPc)
                    score += 2
                if (chordPcs.length === unique.length)
                    score -= 2
                if (score < bestScore) {
                    bestScore = score
                    best = { rootPc: rootPc, qualityId: qualityId }
                }
            }
        }

        if (!best) {
            setStatus("The four selected notes do not match one of the plugin's supported chord types.", true)
            return
        }

        progressionModel.setProperty(selectedChordIndex, "rootPc", best.rootPc)
        progressionModel.setProperty(selectedChordIndex, "qualityId", best.qualityId)
        progressionModel.setProperty(selectedChordIndex, "roman", "Analyzed")
        for (var j = 0; j < ids.length; ++j) {
            if (!setVoicePitch(selectedChordIndex, ids[j], pitches[j])) {
                setStatus("Chord analysis succeeded, but one part could not be mapped to a chord member.", true)
                return
            }
        }
        touchUi()
        setStatus("Loaded " + chordSymbol(selectedChord()) + " and its exact four-part voicing from the score.", false)
    }

    // ---------- Preview ----------

    function saveCurrentSelection() {
        var result = { tick: -1, isRange: false, startTick: -1, endTick: -1, startStaff: 0, endStaff: 4 }
        if (!curScore)
            return result
        try {
            var selection = curScore.selection
            result.isRange = selection.isRange
            if (selection.isRange && selection.startSegment) {
                result.startTick = selection.startSegment.tick
                result.endTick = selection.endSegment ? selection.endSegment.tick : result.startTick + division
                result.startStaff = selection.startStaff
                result.endStaff = selection.endStaff
                result.tick = result.startTick
            } else {
                result.tick = selectionStartTick(false)
            }
        } catch (ignored) {}
        return result
    }

    function restoreSavedSelection() {
        if (!curScore || !savedSelection)
            return
        try {
            curScore.selection.clear()
            if (savedSelection.isRange && savedSelection.startTick >= 0) {
                curScore.selection.selectRange(savedSelection.startTick, savedSelection.endTick,
                                               savedSelection.startStaff, savedSelection.endStaff)
            } else if (savedSelection.tick >= 0) {
                var bounds = mappedStaffBounds()
                curScore.selection.selectRange(savedSelection.tick, savedSelection.tick + division,
                                               bounds.minimum, bounds.maximum + 1)
            }
        } catch (ignored) {}
    }

    function previewSelectedChord() {
        var chord = selectedChord()
        if (!chord) {
            setStatus("Add or select a chord to preview.", true)
            return
        }
        if (previewActive)
            finishPreview("Previous preview stopped.")
        if (!validateStaffMapping(true))
            return

        savedSelection = saveCurrentSelection()
        previewOriginalEndTick = -1
        var previewDurationIndex = 4 // quarter note
        try {
            curScore.startCmd()
            curScore.appendMeasures(1)
            var previewMeasure = curScore.lastMeasure
            if (!previewMeasure || !previewMeasure.firstSegment)
                throw new Error("MuseScore did not expose the temporary preview measure.")
            // Appending first lets MuseScore calculate the exact start tick,
            // including irregular/pickup measures and changing time signatures.
            previewOriginalEndTick = previewMeasure.firstSegment.tick
            insertChordAtTick(chord, previewOriginalEndTick, previewDurationIndex)
            curScore.endCmd()
            previewActive = true
            selectInsertedRange(previewOriginalEndTick, previewOriginalEndTick + durationTicks(previewDurationIndex))
            cmd("command://playback/reload-playback-cache")
            cmd("command://playback/play-selection")
            previewTimer.restart()
            setStatus("Previewing " + chordSymbol(chord) + ". The temporary measure will be undone automatically.", false)
        } catch (error) {
            try { curScore.endCmd(true) } catch (ignored) {}
            previewActive = false
            restoreSavedSelection()
            setStatus("Preview failed: " + error, true)
        }
    }

    function finishPreview(message) {
        previewTimer.stop()
        if (!previewActive)
            return
        try { cmd("command://playback/stop") } catch (ignored1) {}
        try { cmd("undo") } catch (ignored2) {}
        previewActive = false
        restoreSavedSelection()
        setStatus(message, false)
    }

    // ---------- Lifecycle ----------

    onRun: {
        if (!curScore) {
            setStatus("Open a score before running Masala Arrange Helper.", true)
            return
        }
        t1StaffNumber = 1
        t2StaffNumber = Math.min(2, curScore.nstaves)
        bariStaffNumber = Math.min(3, curScore.nstaves)
        bassStaffNumber = Math.min(4, curScore.nstaves)
        rebuildPalette()
        if (curScore.nstaves < 4)
            setStatus("Open or create a score with at least four staves before inserting chords.", true)
    }

    Component.onDestruction: {
        if (previewActive)
            finishPreview("Preview stopped.")
    }

    // ---------- Interface ----------

    Rectangle {
        anchors.fill: parent
        color: systemPalette.window

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Masala Arrange Helper"
                    font.pixelSize: 22
                    font.bold: true
                    Layout.rightMargin: 12
                }

                Label { text: "Key" }
                ComboBox {
                    id: keyCombo
                    Layout.preferredWidth: 82
                    model: root.noteNames()
                    currentIndex: root.currentKeyPc
                    onActivated: function(index) { root.changeKey(index) }
                }

                Label { text: "Mode" }
                ComboBox {
                    id: modeCombo
                    Layout.preferredWidth: 145
                    model: ["Major", "Natural minor", "Harmonic minor"]
                    currentIndex: root.currentModeId === "major" ? 0 : (root.currentModeId === "naturalMinor" ? 1 : 2)
                    onActivated: function(index) {
                        root.currentModeId = index === 0 ? "major" : (index === 1 ? "naturalMinor" : "harmonicMinor")
                        root.rebuildPalette()
                    }
                }

                CheckBox {
                    text: "7th chords"
                    checked: root.useSevenths
                    onToggled: {
                        root.useSevenths = checked
                        root.rebuildPalette()
                    }
                }

                CheckBox {
                    text: "Prefer flats"
                    checked: root.preferFlats
                    onToggled: {
                        root.preferFlats = checked
                        root.rebuildPalette()
                        root.touchUi()
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Close"
                    enabled: !root.previewActive
                    onClicked: root.quit()
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Diatonic chord palette"
                            font.bold: true
                        }
                        Label {
                            text: "Click to add, or drag a card into the progression lane."
                            opacity: 0.75
                        }
                        Item { Layout.fillWidth: true }
                        Label { text: "New-card duration" }
                        ComboBox {
                            Layout.preferredWidth: 130
                            model: root.durationDefinitions
                            textRole: "text"
                            currentIndex: root.defaultDurationIndex
                            onActivated: function(index) { root.defaultDurationIndex = index }
                        }
                        Button {
                            text: "+ Custom"
                            onClicked: root.addCustomChord()
                        }
                    }

                    GridView {
                        id: paletteView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: false
                        cellWidth: width / 7
                        cellHeight: 102
                        model: paletteModel
                        interactive: false

                        delegate: Item {
                            id: paletteDelegate
                            width: paletteView.cellWidth
                            height: paletteView.cellHeight
                            property int paletteIndex: index

                            Rectangle {
                                id: paletteCard
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 6
                                color: systemPalette.base
                                border.color: systemPalette.mid
                                border.width: 1
                                property int paletteIndex: paletteDelegate.paletteIndex

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: roman
                                        font.bold: true
                                        font.pixelSize: 17
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.noteNameFromPc(rootPc) + root.qualitySuffix(qualityId)
                                        font.pixelSize: 15
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.qualityDefinition(qualityId).name
                                        font.pixelSize: 10
                                        opacity: 0.7
                                    }
                                }
                            }

                            Rectangle {
                                id: paletteGhost
                                parent: root
                                z: 1000
                                visible: paletteMouse.drag.active
                                width: 116
                                height: 86
                                radius: 6
                                color: systemPalette.highlight
                                border.color: systemPalette.highlightedText
                                opacity: 0.92
                                property int paletteIndex: paletteDelegate.paletteIndex
                                Drag.active: paletteMouse.drag.active
                                Drag.source: paletteGhost
                                Drag.keys: ["masalaPalette"]
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                Column {
                                    anchors.centerIn: parent
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: roman
                                        color: systemPalette.highlightedText
                                        font.bold: true
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.noteNameFromPc(rootPc) + root.qualitySuffix(qualityId)
                                        color: systemPalette.highlightedText
                                    }
                                }
                            }

                            MouseArea {
                                id: paletteMouse
                                anchors.fill: paletteCard
                                drag.target: paletteGhost
                                drag.threshold: 6
                                property bool moved: false
                                onPressed: function(mouse) {
                                    moved = false
                                    var point = paletteCard.mapToItem(root, 0, 0)
                                    paletteGhost.x = point.x
                                    paletteGhost.y = point.y
                                }
                                onPositionChanged: function(mouse) {
                                    if (drag.active)
                                        moved = true
                                }
                                onReleased: function(mouse) {
                                    if (moved)
                                        paletteGhost.Drag.drop()
                                }
                                onClicked: function(mouse) {
                                    if (!moved)
                                        root.addPaletteChord(paletteDelegate.paletteIndex, progressionModel.count)
                                }
                            }
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: 188

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Progression"
                            font.bold: true
                        }
                        Label {
                            text: progressionModel.count === 0
                                  ? "Drop or click chords above."
                                  : progressionModel.count + " chord" + (progressionModel.count === 1 ? "" : "s")
                            opacity: 0.75
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "←"
                            enabled: root.selectedChordIndex > 0
                            onClicked: root.moveSelected(-1)
                        }
                        Button {
                            text: "→"
                            enabled: root.selectedChordIndex >= 0 && root.selectedChordIndex < progressionModel.count - 1
                            onClicked: root.moveSelected(1)
                        }
                        Button {
                            text: "Duplicate"
                            enabled: root.selectedChordIndex >= 0
                            onClicked: root.duplicateSelectedChord()
                        }
                        Button {
                            text: "Delete"
                            enabled: root.selectedChordIndex >= 0
                            onClicked: root.deleteSelectedChord()
                        }
                        Button {
                            text: "Clear"
                            enabled: progressionModel.count > 0
                            onClicked: root.clearProgression()
                        }
                    }

                    DropArea {
                        id: progressionDropArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        keys: ["masalaPalette", "masalaProgression"]

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: systemPalette.base
                            border.color: progressionDropArea.containsDrag ? systemPalette.highlight : systemPalette.mid
                            border.width: progressionDropArea.containsDrag ? 2 : 1
                        }

                        ListView {
                            id: progressionView
                            anchors.fill: parent
                            anchors.margins: 5
                            orientation: ListView.Horizontal
                            spacing: 7
                            clip: true
                            model: progressionModel
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Item {
                                id: progressionDelegate
                                width: 132
                                height: progressionView.height - 2
                                property int chordUid: uid
                                property int chordIndex: index

                                Rectangle {
                                    id: progressionCard
                                    anchors.fill: parent
                                    radius: 6
                                    color: root.selectedChordIndex === index ? systemPalette.highlight : systemPalette.base
                                    border.color: root.selectedChordIndex === index ? systemPalette.highlightedText : systemPalette.mid
                                    border.width: root.selectedChordIndex === index ? 2 : 1
                                    property int chordUid: progressionDelegate.chordUid

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 1

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label {
                                                text: roman
                                                color: root.selectedChordIndex === index ? systemPalette.highlightedText : systemPalette.text
                                                font.bold: true
                                            }
                                            Item { Layout.fillWidth: true }
                                            Label {
                                                text: root.chordSymbol(progressionModel.get(index))
                                                color: root.selectedChordIndex === index ? systemPalette.highlightedText : systemPalette.text
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 1
                                            color: root.selectedChordIndex === index ? systemPalette.highlightedText : systemPalette.mid
                                            opacity: 0.45
                                        }

                                        Repeater {
                                            model: [
                                                { id: "t1", label: "T1" },
                                                { id: "t2", label: "T2" },
                                                { id: "bari", label: "Bar" },
                                                { id: "bass", label: "B" }
                                            ]
                                            delegate: RowLayout {
                                                Layout.fillWidth: true
                                                Label {
                                                    text: modelData.label
                                                    color: root.selectedChordIndex === progressionDelegate.chordIndex
                                                           ? systemPalette.highlightedText : systemPalette.text
                                                    font.pixelSize: 10
                                                }
                                                Item { Layout.fillWidth: true }
                                                Label {
                                                    text: root.midiNoteName(root.voicePitch(progressionModel.get(progressionDelegate.chordIndex), modelData.id))
                                                    color: root.selectedChordIndex === progressionDelegate.chordIndex
                                                           ? systemPalette.highlightedText : systemPalette.text
                                                    font.bold: true
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }

                                        Item { Layout.fillHeight: true }
                                        Label {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: root.durationAt(durationIndex).text
                                            color: root.selectedChordIndex === index ? systemPalette.highlightedText : systemPalette.text
                                            font.pixelSize: 9
                                            opacity: 0.8
                                        }
                                    }
                                }

                                Rectangle {
                                    id: progressionGhost
                                    parent: root
                                    z: 1000
                                    visible: progressionMouse.drag.active
                                    width: 126
                                    height: 120
                                    radius: 6
                                    color: systemPalette.highlight
                                    border.color: systemPalette.highlightedText
                                    opacity: 0.92
                                    property int chordUid: progressionDelegate.chordUid
                                    Drag.active: progressionMouse.drag.active
                                    Drag.source: progressionGhost
                                    Drag.keys: ["masalaProgression"]
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2

                                    Column {
                                        anchors.centerIn: parent
                                        Label {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: roman
                                            color: systemPalette.highlightedText
                                            font.bold: true
                                        }
                                        Label {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.chordSymbol(progressionModel.get(progressionDelegate.chordIndex))
                                            color: systemPalette.highlightedText
                                        }
                                    }
                                }

                                MouseArea {
                                    id: progressionMouse
                                    anchors.fill: progressionCard
                                    drag.target: progressionGhost
                                    drag.threshold: 6
                                    property bool moved: false
                                    onPressed: function(mouse) {
                                        moved = false
                                        root.selectedChordIndex = progressionDelegate.chordIndex
                                        root.touchUi()
                                        var point = progressionCard.mapToItem(root, 0, 0)
                                        progressionGhost.x = point.x
                                        progressionGhost.y = point.y
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (drag.active)
                                            moved = true
                                    }
                                    onReleased: function(mouse) {
                                        if (moved)
                                            progressionGhost.Drag.drop()
                                    }
                                    onClicked: function(mouse) {
                                        root.selectedChordIndex = progressionDelegate.chordIndex
                                        root.touchUi()
                                    }
                                }
                            }
                        }

                        onDropped: function(drop) {
                            var cardWidth = 139
                            var targetIndex = Math.floor((drop.x + progressionView.contentX) / cardWidth)
                            targetIndex = root.clamp(targetIndex, 0, progressionModel.count)
                            if (drop.source && drop.source.paletteIndex !== undefined) {
                                root.addPaletteChord(drop.source.paletteIndex, targetIndex)
                                drop.acceptProposedAction()
                            } else if (drop.source && drop.source.chordUid !== undefined) {
                                var fromIndex = root.indexForUid(drop.source.chordUid)
                                if (fromIndex >= 0) {
                                    if (targetIndex >= progressionModel.count)
                                        targetIndex = progressionModel.count - 1
                                    root.moveChord(fromIndex, targetIndex)
                                    drop.acceptProposedAction()
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 9

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 760

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: root.selectedChord() ? "Edit " + root.chordSymbol(root.selectedChord()) : "Chord editor"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            Item { Layout.fillWidth: true }
                            Label { text: "Root" }
                            ComboBox {
                                Layout.preferredWidth: 78
                                enabled: root.selectedChord() !== null
                                model: root.noteNames()
                                currentIndex: root.selectedChord() ? root.selectedChord().rootPc : 0
                                onActivated: function(index) { root.changeSelectedRoot(index) }
                            }
                            Label { text: "Quality" }
                            ComboBox {
                                Layout.preferredWidth: 175
                                enabled: root.selectedChord() !== null
                                model: root.qualityChoices
                                textRole: "text"
                                currentIndex: root.selectedChord() ? root.qualityIndex(root.selectedChord().qualityId) : 0
                                onActivated: function(index) { root.changeSelectedQuality(root.qualityChoices[index].id) }
                            }
                            Label { text: "Duration" }
                            ComboBox {
                                Layout.preferredWidth: 125
                                enabled: root.selectedChord() !== null
                                model: root.durationDefinitions
                                textRole: "text"
                                currentIndex: root.selectedChord() ? root.selectedChord().durationIndex : root.defaultDurationIndex
                                onActivated: function(index) { root.setSelectedChordProperty("durationIndex", index) }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: systemPalette.mid
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.preferredWidth: 82
                                text: "Part"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 192
                                text: "Chord member"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 68
                                text: "Octave"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 62
                                text: "Pitch"
                                font.bold: true
                            }
                            Label {
                                Layout.fillWidth: true
                                text: "Move through the vertical voicing"
                                font.bold: true
                            }
                        }

                        Repeater {
                            model: [
                                { id: "t1", label: "Tenor 1" },
                                { id: "t2", label: "Tenor 2" },
                                { id: "bari", label: "Baritone" },
                                { id: "bass", label: "Bass" }
                            ]

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                property string voiceId: modelData.id

                                Label {
                                    Layout.preferredWidth: 82
                                    text: modelData.label
                                    font.bold: true
                                }

                                ComboBox {
                                    Layout.preferredWidth: 192
                                    enabled: root.selectedChord() !== null
                                    model: root.toneOptionsForSelected()
                                    currentIndex: root.selectedChord() ? root.getVoiceTone(root.selectedChord(), voiceId) : 0
                                    onActivated: function(index) { root.setSelectedVoiceTone(voiceId, index) }
                                }

                                SpinBox {
                                    Layout.preferredWidth: 68
                                    from: 0
                                    to: 8
                                    editable: true
                                    enabled: root.selectedChord() !== null
                                    value: root.selectedChord() ? root.getVoiceOctave(root.selectedChord(), voiceId) : 3
                                    onValueModified: root.setSelectedVoiceOctave(voiceId, value)
                                }

                                Label {
                                    Layout.preferredWidth: 62
                                    text: root.midiNoteName(root.selectedVoicePitch(voiceId))
                                    font.bold: true
                                }

                                Button {
                                    text: "−8va"
                                    enabled: root.selectedChord() !== null
                                    onClicked: root.shiftSelectedVoiceOctave(voiceId, -1)
                                }
                                Button {
                                    text: "◀ tone"
                                    enabled: root.selectedChord() !== null
                                    onClicked: root.stepSelectedVoice(voiceId, -1)
                                }
                                Button {
                                    text: "tone ▶"
                                    enabled: root.selectedChord() !== null
                                    onClicked: root.stepSelectedVoice(voiceId, 1)
                                }
                                Button {
                                    text: "+8va"
                                    enabled: root.selectedChord() !== null
                                    onClicked: root.shiftSelectedVoiceOctave(voiceId, 1)
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: systemPalette.mid
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "Smooth from previous"
                                enabled: root.selectedChord() !== null
                                onClicked: root.optimizeSelected("smooth")
                            }
                            Button {
                                text: "Close"
                                enabled: root.selectedChord() !== null
                                onClicked: root.optimizeSelected("close")
                            }
                            Button {
                                text: "Spread"
                                enabled: root.selectedChord() !== null
                                onClicked: root.optimizeSelected("spread")
                            }
                            Button {
                                text: "Rotate roles ↓"
                                enabled: root.selectedChord() !== null
                                onClicked: root.rotateAssignments(1)
                            }
                            Button {
                                text: "Rotate roles ↑"
                                enabled: root.selectedChord() !== null
                                onClicked: root.rotateAssignments(-1)
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Frame {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ScrollView {
                                anchors.fill: parent
                                clip: true
                                Label {
                                    width: parent.width
                                    text: root.selectedWarnings()
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignTop
                                    padding: 6
                                }
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 380

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 7

                        Label {
                            text: "Score connection"
                            font.bold: true
                            font.pixelSize: 16
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Map each part to its 1-based staff number. The defaults assume T1, T2, Baritone, Bass from top to bottom."
                            wrapMode: Text.WordWrap
                            opacity: 0.8
                        }

                        GridLayout {
                            columns: 4
                            columnSpacing: 7
                            rowSpacing: 4
                            Layout.fillWidth: true

                            Repeater {
                                model: [
                                    { id: "t1", label: "T1" },
                                    { id: "t2", label: "T2" },
                                    { id: "bari", label: "Baritone" },
                                    { id: "bass", label: "Bass" }
                                ]
                                delegate: ColumnLayout {
                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        font.bold: true
                                    }
                                    SpinBox {
                                        from: 1
                                        to: curScore ? Math.max(1, curScore.nstaves) : 4
                                        editable: true
                                        value: root.staffNumberForVoice(modelData.id)
                                        onValueModified: root.setStaffNumberForVoice(modelData.id, value)
                                    }
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Analyze notes at score selection"
                            enabled: root.selectedChord() !== null && !root.previewActive
                            onClicked: root.analyzeSelectedScoreChord()
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Analysis reads one note from each mapped staff at the selected beat, identifies a supported chord, and loads the exact part assignments and octaves."
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            opacity: 0.72
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: systemPalette.mid
                        }

                        Button {
                            Layout.fillWidth: true
                            text: root.previewActive ? "Stop preview" : "Preview selected chord"
                            enabled: root.selectedChord() !== null
                            onClicked: {
                                if (root.previewActive)
                                    root.finishPreview("Preview stopped.")
                                else
                                    root.previewSelectedChord()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Preview temporarily adds a quarter-note measure at the end of the score, plays the selected four-part voicing with the score's instruments, then undoes that measure."
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            opacity: 0.72
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Insert selected chord"
                            enabled: root.selectedChord() !== null && !root.previewActive
                            onClicked: root.insertSelectedIntoScore()
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Insert full progression"
                            enabled: progressionModel.count > 0 && !root.previewActive
                            onClicked: root.insertProgressionIntoScore()
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Insertion starts at the selected score beat and writes voice 1 on each mapped staff. Existing notes at those locations may be replaced or combined by MuseScore's note-entry rules, so save first when testing."
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            opacity: 0.72
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 5
                color: root.statusIsError ? "#552020" : systemPalette.base
                border.color: root.statusIsError ? "#c65d5d" : systemPalette.mid

                Label {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: root.statusMessage
                    color: root.statusIsError ? "#ffffff" : systemPalette.text
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
