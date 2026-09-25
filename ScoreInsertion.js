// Score insertion helpers shared by MuseScore QML and Node tests.
// SPDX-License-Identifier: GPL-3.0-only

function defaultStaffMapping(staffCount) {
    staffCount = Math.max(1, staffCount)
    if (staffCount === 1)
        return { t1: 1, t2: 1, bari: 1, bass: 1 }
    if (staffCount === 2)
        return { t1: 1, t2: 1, bari: 2, bass: 2 }
    if (staffCount === 3)
        return { t1: 1, t2: 2, bari: 3, bass: 3 }

    var firstVocalStaff = staffCount - 3
    return {
        t1: firstVocalStaff,
        t2: firstVocalStaff + 1,
        bari: firstVocalStaff + 2,
        bass: firstVocalStaff + 3
    }
}

function groupEntriesByStaff(entries) {
    var result = []
    var groupIndexes = {}

    for (var i = 0; i < entries.length; ++i) {
        var entry = entries[i]
        var key = "staff-" + entry.staffNumber
        var groupIndex = groupIndexes[key]
        if (groupIndex === undefined) {
            groupIndex = result.length
            groupIndexes[key] = groupIndex
            result.push({ staffNumber: entry.staffNumber, pitches: [] })
        }

        var pitches = result[groupIndex].pitches
        var alreadyPresent = false
        for (var p = 0; p < pitches.length; ++p) {
            if (pitches[p] === entry.pitch) {
                alreadyPresent = true
                break
            }
        }
        if (!alreadyPresent)
            pitches.push(entry.pitch)
    }

    return result
}

function assignPitchesToVoices(voiceEntries, pitchesByStaff) {
    var sortedByStaff = {}
    var voiceCounts = {}

    for (var i = 0; i < voiceEntries.length; ++i) {
        var staffKey = "staff-" + voiceEntries[i].staffNumber
        voiceCounts[staffKey] = (voiceCounts[staffKey] || 0) + 1
    }

    for (var key in voiceCounts) {
        var source = pitchesByStaff[key] || []
        if (source.length < voiceCounts[key])
            return null
        var copy = []
        for (var p = 0; p < source.length; ++p)
            copy.push(source[p])
        copy.sort(function(left, right) { return left - right })
        sortedByStaff[key] = copy
    }

    var staffOffsets = {}
    var result = []
    for (var v = 0; v < voiceEntries.length; ++v) {
        var voiceKey = "staff-" + voiceEntries[v].staffNumber
        var offset = staffOffsets[voiceKey] || 0
        result.push(sortedByStaff[voiceKey][offset])
        staffOffsets[voiceKey] = offset + 1
    }
    return result
}
