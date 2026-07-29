// Staff-preview pitch spelling and vertical placement helpers.
// SPDX-License-Identifier: GPL-3.0-only

var sharpNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
var flatNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
var letterPositions = ({ "C": 0, "D": 1, "E": 2, "F": 3, "G": 4, "A": 5, "B": 6 })

function modulo(value, modulus) {
    return ((value % modulus) + modulus) % modulus
}

function pitchClassName(pitch, preferFlats) {
    var names = preferFlats ? flatNames : sharpNames
    return names[modulo(pitch, 12)]
}

function noteName(pitch, preferFlats) {
    if (pitch < 0 || pitch > 127)
        return "—"
    return pitchClassName(pitch, preferFlats) + (Math.floor(pitch / 12) - 1)
}

function accidental(pitch, preferFlats) {
    var name = pitchClassName(pitch, preferFlats)
    return name.length > 1 ? name.slice(1) : ""
}

function diatonicPosition(pitch, preferFlats) {
    var name = pitchClassName(pitch, preferFlats)
    var octave = Math.floor(pitch / 12) - 1
    return octave * 7 + letterPositions[name.charAt(0)]
}

function bottomLinePosition(clef) {
    // Treble bottom line: E4. Bass bottom line: G2.
    return clef === "bass" ? 18 : 30
}

function staffStepFromBottom(pitch, clef, preferFlats) {
    return diatonicPosition(pitch, preferFlats) - bottomLinePosition(clef)
}

function ledgerSteps(staffStep) {
    var result = []
    var step
    if (staffStep < 0) {
        for (step = -2; step >= staffStep; step -= 2)
            result.push(step)
    } else if (staffStep > 8) {
        for (step = 10; step <= staffStep; step += 2)
            result.push(step)
    }
    return result
}
