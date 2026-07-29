// SPDX-License-Identifier: GPL-3.0-only

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const projectRoot = path.resolve(__dirname, "..");
const qml = fs.readFileSync(path.join(projectRoot, "MasalaArrangeHelper.qml"), "utf8");

function delimitersOutsideStringsAndComments(source) {
    const pairs = { "{": "}", "[": "]", "(": ")" };
    const closing = new Set(Object.values(pairs));
    const stack = [];
    let quote = "";
    let lineComment = false;
    let blockComment = false;
    let escaped = false;

    for (let index = 0; index < source.length; ++index) {
        const char = source[index];
        const next = source[index + 1];

        if (lineComment) {
            if (char === "\n")
                lineComment = false;
            continue;
        }
        if (blockComment) {
            if (char === "*" && next === "/") {
                blockComment = false;
                ++index;
            }
            continue;
        }
        if (quote) {
            if (escaped) {
                escaped = false;
            } else if (char === "\\") {
                escaped = true;
            } else if (char === quote) {
                quote = "";
            }
            continue;
        }
        if (char === "/" && next === "/") {
            lineComment = true;
            ++index;
        } else if (char === "/" && next === "*") {
            blockComment = true;
            ++index;
        } else if (char === '"' || char === "'") {
            quote = char;
        } else if (pairs[char]) {
            stack.push({ char, index });
        } else if (closing.has(char)) {
            const opening = stack.pop();
            assert.ok(opening, `unexpected ${char} at offset ${index}`);
            assert.equal(pairs[opening.char], char, `mismatched ${opening.char}${char}`);
        }
    }

    assert.equal(quote, "", "unterminated string");
    assert.equal(blockComment, false, "unterminated block comment");
    assert.deepEqual(stack, [], "unclosed delimiter");
}

function matchingBrace(source, openingIndex) {
    let depth = 0;
    let quote = "";
    let lineComment = false;
    let blockComment = false;
    let escaped = false;

    for (let index = openingIndex; index < source.length; ++index) {
        const char = source[index];
        const next = source[index + 1];

        if (lineComment) {
            if (char === "\n")
                lineComment = false;
            continue;
        }
        if (blockComment) {
            if (char === "*" && next === "/") {
                blockComment = false;
                ++index;
            }
            continue;
        }
        if (quote) {
            if (escaped)
                escaped = false;
            else if (char === "\\")
                escaped = true;
            else if (char === quote)
                quote = "";
            continue;
        }
        if (char === "/" && next === "/") {
            lineComment = true;
            ++index;
        } else if (char === "/" && next === "*") {
            blockComment = true;
            ++index;
        } else if (char === '"' || char === "'") {
            quote = char;
        } else if (char === "{") {
            ++depth;
        } else if (char === "}") {
            --depth;
            if (depth === 0)
                return index;
        }
    }
    return -1;
}

test("QML delimiters, strings, and comments are balanced", () => {
    delimitersOutsideStringsAndComments(qml);
});

test("QML ids are unique", () => {
    const ids = [...qml.matchAll(/^\s*id:\s*([A-Za-z][A-Za-z0-9_]*)/gm)].map(match => match[1]);
    const duplicates = ids.filter((id, index) => ids.indexOf(id) !== index);
    assert.deepEqual(duplicates, []);
});

test("all named QML JavaScript functions parse", () => {
    const starts = [...qml.matchAll(/^\s*function\s+[A-Za-z][A-Za-z0-9_]*\s*\(/gm)];
    assert.ok(starts.length > 0);

    for (const start of starts) {
        const openingBrace = qml.indexOf("{", start.index);
        const closingBrace = matchingBrace(qml, openingBrace);
        assert.notEqual(closingBrace, -1, `unclosed function at offset ${start.index}`);
        const functionSource = qml.slice(start.index, closingBrace + 1);
        assert.doesNotThrow(() => new vm.Script(functionSource));
    }
});

test("staff preview helper is valid JavaScript", () => {
    const helperPath = path.join(projectRoot, "StaffPreview.js");
    const helperSource = fs.readFileSync(helperPath, "utf8");
    assert.doesNotThrow(() => new vm.Script(helperSource, { filename: helperPath }));
});
