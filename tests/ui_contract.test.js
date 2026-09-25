// SPDX-License-Identifier: GPL-3.0-only

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const projectRoot = path.resolve(__dirname, "..");
const qmlPath = path.join(projectRoot, "MasalaArrangeHelper.qml");
const qml = fs.readFileSync(qmlPath, "utf8");

function loadStaffPreview() {
    const helperPath = path.join(projectRoot, "StaffPreview.js");
    const helperSource = fs.readFileSync(helperPath, "utf8");
    const context = {};
    vm.createContext(context);
    vm.runInContext(helperSource, context, { filename: helperPath });
    return context;
}

test("main interface is one responsive scrollable page", () => {
    assert.match(qml, /property bool narrowLayout:\s*width < \d+/);
    assert.match(qml, /ScrollView\s*{\s*id:\s*mainScroll/);
    assert.match(qml, /ScrollBar\.horizontal\.policy:\s*ScrollBar\.AlwaysOff/);
    assert.match(qml, /id:\s*voicingPreviewGrid[\s\S]*?columns:\s*root\.narrowLayout \? 1 : 2/);
});

test("plugin is modeless and maps voices to the bottom four staves", () => {
    assert.match(qml, /pluginType:\s*"dock"/);
    assert.match(qml, /import QtQuick\.Window/);
    assert.match(qml, /^\s*implicitWidth:\s*980\s*$/m);
    assert.match(qml, /^\s*implicitHeight:\s*760\s*$/m);
    assert.doesNotMatch(qml, /^\s*width:\s*980\s*$/m);
    assert.doesNotMatch(qml, /^\s*height:\s*760\s*$/m);
    assert.match(qml, /property var hostWindow:\s*Window\.window/);
    assert.match(qml, /hostWindow\.maximumWidth = 16777215/);
    assert.match(qml, /hostWindow\.maximumHeight = 16777215/);
    assert.match(qml, /width:\s*root\.hostWindow \? root\.hostWindow\.width : root\.implicitWidth/);
    assert.match(qml, /height:\s*root\.hostWindow \? root\.hostWindow\.height : root\.implicitHeight/);
    assert.match(qml, /Insertion\.defaultStaffMapping\(curScore\.nstaves\)/);
});

test("shared staff mappings insert one block chord per staff", () => {
    assert.doesNotMatch(qml, /Each vocal part must be mapped to a different staff/);
    assert.doesNotMatch(qml, /curScore\.nstaves < 4/);
    assert.match(qml, /Insertion\.groupEntriesByStaff\(entries\)/);
    assert.match(qml, /cursor\.addNote\(group\.pitches\[0\]\)/);
    assert.match(qml, /cursor\.addNote\(group\.pitches\[pitchIndex\], true\)/);
    assert.match(qml, /Insertion\.assignPitchesToVoices\(voiceEntries, pitchesByStaff\)/);
});

test("large score actions appear before voicing controls", () => {
    const actionBar = qml.indexOf("id: primaryActionBar");
    const voicing = qml.indexOf("id: voicingPreviewGrid");

    assert.ok(actionBar >= 0, "primary action bar exists");
    assert.ok(voicing > actionBar, "primary action bar appears before voicing controls");
    assert.match(qml, /id:\s*insertChordButton[\s\S]*?Layout\.preferredHeight:\s*52/);
    assert.match(qml, /id:\s*insertProgressionButton[\s\S]*?Layout\.preferredHeight:\s*52/);
});

test("advanced controls start collapsed and remain available", () => {
    assert.match(qml, /property bool advancedExpanded:\s*false/);
    assert.match(qml, /text:\s*root\.advancedExpanded \? "Advanced ▾" : "Advanced ▸"/);
    assert.match(qml, /id:\s*advancedPanel[\s\S]*?visible:\s*root\.advancedExpanded/);
    assert.match(qml, /text:\s*"Analyze score selection"/);
    assert.match(qml, /text:\s*"Prefer flats"/);
});

test("voicing contains live four-staff preview with requested clefs", () => {
    assert.match(qml, /import "StaffPreview\.js" as StaffPreview/);
    assert.match(qml, /Canvas\s*{\s*id:\s*staffPreviewCanvas/);
    assert.match(qml, /\{ id: "t1",\s*label: "T1",\s*clef: "treble" \}/);
    assert.match(qml, /\{ id: "t2",\s*label: "T2",\s*clef: "treble" \}/);
    assert.match(qml, /\{ id: "bari",\s*label: "Baritone",\s*clef: "treble" \}/);
    assert.match(qml, /\{ id: "bass",\s*label: "Bass",\s*clef: "bass" \}/);
    assert.match(qml, /onRevisionChanged:\s*requestPaint\(\)/);
});

test("progression cards read duration from their model row", () => {
    assert.match(
        qml,
        /root\.durationAt\(progressionModel\.get\([\s\S]*?progressionCardItem\.chordIndex\)\.durationIndex\)\.text/
    );
    assert.doesNotMatch(qml, /root\.durationAt\(durationIndex\)\.text/);
});

test("compact cards preserve palette and progression drag-and-drop", () => {
    assert.match(qml, /Drag\.keys:\s*\["masalaPalette"\]/);
    assert.match(qml, /Drag\.keys:\s*\["masalaProgression"\]/);
    assert.match(qml, /DropArea\s*{\s*id:\s*progressionDropArea/);
    assert.match(qml, /keys:\s*\["masalaPalette",\s*"masalaProgression"\]/);
});

test("staff math places notes relative to clef bottom lines", () => {
    const preview = loadStaffPreview();

    assert.equal(preview.staffStepFromBottom(64, "treble", false), 0); // E4
    assert.equal(preview.staffStepFromBottom(60, "treble", false), -2); // C4
    assert.equal(preview.staffStepFromBottom(77, "treble", false), 8); // F5
    assert.equal(preview.staffStepFromBottom(43, "bass", false), 0); // G2
    assert.equal(preview.staffStepFromBottom(57, "bass", false), 8); // A3
});

test("staff math spells accidentals and identifies ledger lines", () => {
    const preview = loadStaffPreview();

    assert.equal(preview.noteName(61, false), "C♯4");
    assert.equal(preview.noteName(61, true), "D♭4");
    assert.equal(preview.accidental(61, false), "♯");
    assert.equal(preview.accidental(61, true), "♭");
    assert.deepEqual(Array.from(preview.ledgerSteps(-4)), [-2, -4]);
    assert.deepEqual(Array.from(preview.ledgerSteps(10)), [10]);
    assert.deepEqual(Array.from(preview.ledgerSteps(4)), []);
});
