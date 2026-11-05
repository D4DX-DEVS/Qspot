const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');

// The routes use the chained Model.find(filter).distinct(field) form (faculty
// assignments, admin search, notifications); the D1 stand-in must support it.
const Probe = mongoose.model('DistinctProbe', new mongoose.Schema({ speaker: String, tag: String }));
const rows = [
    { _id: 'a1', speaker: 's1', tag: 'x' },
    { _id: 'a2', speaker: 's1', tag: 'x' },
    { _id: 'a3', speaker: 's1', tag: 'y' },
    { _id: 'a4', speaker: 's2', tag: 'z' }
];
// No D1 here: serve the rows from memory, filtered the shim's own way.
const { matches } = mongoose.__internals;
mongoose.__registry.get('DistinctProbe')._rows = async (filter) => rows.filter((row) => matches(row, filter));

test('find(filter).distinct(field) gives the unique values of the matching rows', async () => {
    assert.deepEqual(await Probe.find({ speaker: 's1' }).distinct('tag'), ['x', 'y']);
});

test('find(filter).distinct(field) matches distinct(field, filter)', async () => {
    assert.deepEqual(
        await Probe.find({ speaker: 's1' }).distinct('_id'),
        await Probe.distinct('_id', { speaker: 's1' })
    );
});
