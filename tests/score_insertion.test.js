// SPDX-License-Identifier: GPL-3.0-only

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const projectRoot = path.resolve(__dirname, "..");
const helperPath = path.join(projectRoot, "ScoreInsertion.js");

function loadHelper() {
    const context = {};
    vm.createContext(context);
    vm.runInContext(fs.readFileSync(helperPath, "utf8"), context, { filename: helperPath });
    return context;
}

test("one-staff scores map every part to one block chord", () => {
    const helper = loadHelper();

    assert.deepEqual(
        JSON.parse(JSON.stringify(helper.defaultStaffMapping(1))),
        { t1: 1, t2: 1, bari: 1, bass: 1 }
    );
});

test("two- and three-staff scores use practical shared defaults", () => {
    const helper = loadHelper();

    assert.deepEqual(
        JSON.parse(JSON.stringify(helper.defaultStaffMapping(2))),
        { t1: 1, t2: 1, bari: 2, bass: 2 }
    );
    assert.deepEqual(
        JSON.parse(JSON.stringify(helper.defaultStaffMapping(3))),
        { t1: 1, t2: 2, bari: 3, bass: 3 }
    );
});

test("four-plus staff scores preserve bottom-four vocal mapping", () => {
    const helper = loadHelper();

    assert.deepEqual(
        JSON.parse(JSON.stringify(helper.defaultStaffMapping(8))),
        { t1: 5, t2: 6, bari: 7, bass: 8 }
    );
});

test("parts sharing a staff become one chord and exact unisons are deduplicated", () => {
    const helper = loadHelper();
    const groups = helper.groupEntriesByStaff([
        { staffNumber: 1, pitch: 48 },
        { staffNumber: 1, pitch: 55 },
        { staffNumber: 1, pitch: 60 },
        { staffNumber: 1, pitch: 60 }
    ]);

    assert.deepEqual(
        JSON.parse(JSON.stringify(groups)),
        [{ staffNumber: 1, pitches: [48, 55, 60] }]
    );
});

test("parts can share selected staves while others remain separate", () => {
    const helper = loadHelper();
    const groups = helper.groupEntriesByStaff([
        { staffNumber: 2, pitch: 43 },
        { staffNumber: 2, pitch: 52 },
        { staffNumber: 1, pitch: 60 },
        { staffNumber: 1, pitch: 67 }
    ]);

    assert.deepEqual(
        JSON.parse(JSON.stringify(groups)),
        [
            { staffNumber: 2, pitches: [43, 52] },
            { staffNumber: 1, pitches: [60, 67] }
        ]
    );
});

test("score analysis assigns same-staff notes from low part to high part", () => {
    const helper = loadHelper();
    const pitches = helper.assignPitchesToVoices(
        [
            { voiceId: "bass", staffNumber: 1 },
            { voiceId: "bari", staffNumber: 1 },
            { voiceId: "t2", staffNumber: 1 },
            { voiceId: "t1", staffNumber: 1 }
        ],
        { "staff-1": [67, 48, 60, 55] }
    );

    assert.deepEqual(Array.from(pitches), [48, 55, 60, 67]);
});

test("score analysis rejects a shared staff with too few written notes", () => {
    const helper = loadHelper();
    const pitches = helper.assignPitchesToVoices(
        [
            { voiceId: "bass", staffNumber: 1 },
            { voiceId: "bari", staffNumber: 1 }
        ],
        { "staff-1": [48] }
    );

    assert.equal(pitches, null);
});
