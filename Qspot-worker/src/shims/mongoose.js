// Mongoose-compatible layer over Cloudflare D1. Every model is a "collection"
// inside one table, docs(collection, id, data JSON). The existing model files
// run unchanged: Schema/model/Types come from here, queries are compiled to
// SQL where possible (equality, $in, ranges, $or...) and finished in JS.
// shortcut: filters that cannot compile to SQL scan the whole collection,
// add an expression index in migrations/ if one becomes slow.

const state = { db: null };
const registry = new Map(); // name -> Model, name#proxy -> callable model

const ObjectIdType = function ObjectId() {};
const MixedType = function Mixed() {};

const newId = () => Array.from(crypto.getRandomValues(new Uint8Array(12)), (b) => b.toString(16).padStart(2, '0')).join('');
const isId = (v) => typeof v === 'string' && /^[0-9a-f]{24}$/i.test(v);
const isPlain = (v) => v && typeof v === 'object' && !Array.isArray(v) && !(v instanceof Date) && Object.getPrototypeOf(v) === Object.prototype;

// ---- Schema ----------------------------------------------------------------

const isTypeSpec = (o) => isPlain(o) && 'type' in o && !isPlain(o.type);

function kindOf(t) {
    if (t === Date) return 'date';
    if (t === ObjectIdType) return 'oid';
    if (t === Number) return 'number';
    if (t === Boolean) return 'boolean';
    if (t === String) return 'string';
    return 'mixed';
}

// Flatten a schema definition into { 'a.b': {kind, ref, array, def, sub, selectFalse} }.
function analyze(def, prefix = '', out = {}) {
    for (const [key, raw] of Object.entries(def)) {
        if (key === '_id' && raw === false) continue;
        const path = prefix + key;
        let spec = Array.isArray(raw) ? { type: raw } : raw;
        if (isPlain(spec) && !isTypeSpec(spec)) { analyze(spec, path + '.', out); continue; }
        if (!isPlain(spec)) spec = { type: spec };
        const t = spec.type;
        if (Array.isArray(t)) {
            const el = t[0];
            const info = { array: true, def: spec.default, selectFalse: spec.select === false };
            if (isPlain(el) && !isTypeSpec(el)) info.sub = analyze(el);
            else {
                const inner = isPlain(el) ? el : { type: el };
                info.kind = kindOf(inner.type);
                info.ref = inner.ref;
            }
            out[path] = info;
        } else {
            out[path] = { kind: kindOf(t), ref: spec.ref, def: spec.default, selectFalse: spec.select === false, index: !!spec.index, unique: !!spec.unique };
        }
    }
    return out;
}

class Schema {
    constructor(def, opts = {}) {
        this.def = def;
        this.opts = opts;
        this.paths = analyze(def);
        this.indexes = [];
        this.hooks = { save: [], update: [] };
        this.virtuals = {};
    }
    index(fields, options = {}) { this.indexes.push({ fields, options }); return this; }
    pre(names, fn) {
        for (const n of [].concat(names)) (n === 'save' ? this.hooks.save : this.hooks.update).push(fn);
        return this;
    }
    virtual(name) { return { get: (fn) => { this.virtuals[name] = fn; return this; } }; }
}
Schema.Types = { ObjectId: ObjectIdType, Mixed: MixedType };

// ---- value helpers -----------------------------------------------------------

const getPath = (obj, path) => path.split('.').reduce((o, k) => (o == null ? undefined : o[k]), obj);
function setPath(obj, path, value) {
    const keys = path.split('.');
    let o = obj;
    for (let i = 0; i < keys.length - 1; i++) {
        if (!isPlain(o[keys[i]])) o[keys[i]] = {};
        o = o[keys[i]];
    }
    o[keys[keys.length - 1]] = value;
}
function unsetPath(obj, path) {
    const keys = path.split('.');
    let o = obj;
    for (let i = 0; i < keys.length - 1; i++) { o = o && o[keys[i]]; if (!o) return; }
    delete o[keys[keys.length - 1]];
}
const clone = (v) => {
    if (v instanceof Date) return new Date(v.getTime());
    if (Array.isArray(v)) return v.map(clone);
    if (isPlain(v)) { const o = {}; for (const k of Object.keys(v)) o[k] = clone(v[k]); return o; }
    return v;
};
// ObjectId-like objects (anything with a custom toString) become hex strings.
const normId = (v) => (v && typeof v === 'object' && !(v instanceof Date) && !Array.isArray(v) && !isPlain(v) && !(v instanceof RegExp) ? v.toString() : v);
function normalizeIds(v) {
    if (Array.isArray(v)) return v.map(normalizeIds);
    if (v instanceof Date || v instanceof RegExp) return v;
    if (v && typeof v === 'object') {
        if (!isPlain(v)) return normId(v);
        const o = {};
        for (const k of Object.keys(v)) o[k] = normalizeIds(v[k]);
        return o;
    }
    return v;
}
const comparable = (v) => (v instanceof Date ? v.getTime() : normId(v));

function applyDefaults(paths, obj) {
    for (const [path, info] of Object.entries(paths)) {
        const cur = getPath(obj, path);
        if (cur === undefined && info.def !== undefined) {
            const v = typeof info.def === 'function' ? info.def() : clone(info.def);
            if (v !== undefined) setPath(obj, path, v);
        } else if (cur === undefined && info.array) {
            setPath(obj, path, []);
        } else if (info.array && info.sub && Array.isArray(cur)) {
            cur.forEach((el) => isPlain(el) && applyDefaults(info.sub, el));
        }
    }
}

function revive(paths, obj) {
    for (const [path, info] of Object.entries(paths)) {
        const cur = getPath(obj, path);
        if (cur == null) continue;
        if (info.sub && Array.isArray(cur)) { cur.forEach((el) => isPlain(el) && revive(info.sub, el)); continue; }
        if (info.kind === 'date') setPath(obj, path, Array.isArray(cur) ? cur.map((d) => (d == null ? d : new Date(d))) : new Date(cur));
    }
}

const toStored = (v) => JSON.parse(JSON.stringify(v));

// ---- SQL compile ---------------------------------------------------------------

const lit = (v) => {
    if (v === null || v === undefined) return 'NULL';
    if (v instanceof Date) return `'${v.toISOString()}'`;
    if (typeof v === 'number') return Number.isFinite(v) ? String(v) : 'NULL';
    if (typeof v === 'boolean') return v ? '1' : '0';
    return `'${String(normId(v)).replace(/'/g, "''")}'`;
};
const jp = (path) => `'$.${path}'`;
const colFor = (path) => (path === '_id' ? 'id' : `json_extract(data,${jp(path)})`);
const isOps = (v) => isPlain(v) && Object.keys(v).length > 0 && Object.keys(v).every((k) => k.startsWith('$'));

// SQL for one field condition, or null when it cannot be expressed exactly.
function compileClause(schema, path, cond) {
    if (path.includes('.')) return null;
    const info = schema.paths[path];
    if (info && info.sub) return null;
    const isArr = !!(info && info.array);
    const field = colFor(path);
    const eq = (v) => {
        if (v === null) return isArr ? `json_array_length(data,${jp(path)}) IS NULL` : `${field} IS NULL`;
        if (isArr) return `EXISTS(SELECT 1 FROM json_each(data,${jp(path)}) WHERE value = ${lit(v)})`;
        return `${field} = ${lit(v)}`;
    };
    if (!isOps(cond)) {
        if (cond instanceof RegExp || Array.isArray(cond) || isPlain(cond)) return null;
        return eq(cond);
    }
    const parts = [];
    for (const [op, v] of Object.entries(cond)) {
        switch (op) {
            case '$eq': parts.push(eq(v)); break;
            case '$ne':
                if (v === null) parts.push(`${field} IS NOT NULL`);
                else if (isArr) parts.push(`NOT ${eq(v)}`);
                else parts.push(`(${field} IS NULL OR ${field} != ${lit(v)})`);
                break;
            case '$in': {
                if (!Array.isArray(v) || v.some((x) => x instanceof RegExp)) return null;
                if (!v.length) { parts.push('0'); break; }
                if (v.length > 400) return null; // keeps statements small
                if (isArr || v.includes(null)) { parts.push('(' + v.map(eq).join(' OR ') + ')'); break; }
                parts.push(`${field} IN (${v.map(lit).join(',')})`);
                break;
            }
            case '$nin':
                if (!Array.isArray(v) || v.length > 400) return null;
                if (!v.length) break;
                if (isArr) parts.push('NOT (' + v.map(eq).join(' OR ') + ')');
                else parts.push(`(${field} IS NULL OR ${field} NOT IN (${v.map(lit).join(',')}))`);
                break;
            case '$gt': case '$gte': case '$lt': case '$lte':
                if (isArr || v === null) return null;
                parts.push(`${field} ${{ $gt: '>', $gte: '>=', $lt: '<', $lte: '<=' }[op]} ${lit(v)}`);
                break;
            case '$exists':
                if (isArr) return null;
                parts.push(v ? `${field} IS NOT NULL` : `${field} IS NULL`);
                break;
            default: return null;
        }
    }
    return parts.length ? parts.map((p) => `(${p})`).join(' AND ') : '1';
}

function compileFilter(schema, filter) {
    const parts = [];
    for (const [key, cond] of Object.entries(filter || {})) {
        if (key === '$or' || key === '$and') {
            const subs = cond.map((f) => compileFilter(schema, f));
            if (subs.some((s) => s === null)) return null;
            parts.push('(' + (subs.length ? subs.join(key === '$or' ? ' OR ' : ' AND ') : (key === '$or' ? '0' : '1')) + ')');
        } else if (key.startsWith('$')) {
            return null;
        } else {
            const c = compileClause(schema, key, cond);
            if (c === null) return null;
            parts.push(c);
        }
    }
    return parts.length ? parts.join(' AND ') : '1';
}

// ---- JS matcher (source of truth; SQL is only a pre-filter) ---------------------

const looseEq = (a, b) => comparable(a) === comparable(b);
function matchValue(docVal, cond) {
    const arr = Array.isArray(docVal) ? docVal : null;
    const test = (fn) => (arr ? (arr.length ? arr.some(fn) : fn(undefined)) : fn(docVal));
    if (cond instanceof RegExp) return test((x) => typeof x === 'string' && cond.test(x));
    if (!isOps(cond)) {
        if (cond === null) return test((x) => x == null);
        return test((x) => looseEq(x, cond));
    }
    return Object.entries(cond).every(([op, v]) => {
        switch (op) {
            case '$eq': return v === null ? test((x) => x == null) : test((x) => looseEq(x, v));
            case '$ne': return v === null ? !test((x) => x == null) : !test((x) => looseEq(x, v));
            case '$in': return v.some((c) => (c === null ? test((x) => x == null) : c instanceof RegExp ? test((x) => typeof x === 'string' && c.test(x)) : test((x) => looseEq(x, c))));
            case '$nin': return !v.some((c) => (c === null ? test((x) => x == null) : test((x) => looseEq(x, c))));
            case '$gt': return test((x) => x != null && comparable(x) > comparable(v));
            case '$gte': return test((x) => x != null && comparable(x) >= comparable(v));
            case '$lt': return test((x) => x != null && comparable(x) < comparable(v));
            case '$lte': return test((x) => x != null && comparable(x) <= comparable(v));
            case '$exists': return v ? docVal !== undefined : docVal === undefined;
            case '$not': return !matchValue(docVal, v);
            case '$regex': return test((x) => typeof x === 'string' && new RegExp(v, cond.$options || '').test(x));
            case '$options': return true;
            case '$size': return arr ? arr.length === v : false;
            case '$elemMatch': return arr ? arr.some((el) => (isPlain(el) ? matches(el, v) : matchValue(el, v))) : false;
            default: throw new Error(`Unsupported query operator ${op}`);
        }
    });
}
// Value(s) at a dotted path, walking through arrays of sub-documents.
function valuesAt(doc, path) {
    const keys = path.split('.');
    let cur = [doc];
    keys.forEach((k, i) => {
        const next = [];
        for (const c of cur) {
            if (c == null) continue;
            const v = c[k];
            if (Array.isArray(v) && i < keys.length - 1) next.push(...v); else next.push(v);
        }
        cur = next;
    });
    return cur;
}
function matches(doc, filter) {
    return Object.entries(filter || {}).every(([key, cond]) => {
        if (key === '$or') return cond.some((f) => matches(doc, f));
        if (key === '$and') return cond.every((f) => matches(doc, f));
        if (key === '$nor') return !cond.some((f) => matches(doc, f));
        if (key.includes('.')) {
            const flat = valuesAt(doc, key).flatMap((v) => (Array.isArray(v) ? v : [v]));
            return matchValue(flat.length > 1 ? flat : flat[0], cond);
        }
        return matchValue(doc[key], cond);
    });
}

// ---- Query / Model ---------------------------------------------------------------

const D = () => {
    if (!state.db) throw new Error('D1 binding not set');
    return state.db;
};
const wrapDb = async (fn) => {
    try { return await fn(); } catch (e) {
        if (/UNIQUE constraint failed/i.test(String(e.message))) {
            const err = new Error('E11000 duplicate key error: ' + e.message);
            err.code = 11000;
            throw err;
        }
        throw e;
    }
};

const sortCmp = (sort) => (a, b) => {
    for (const [k, dir] of sort) {
        const av = comparable(getPath(a, k)); const bv = comparable(getPath(b, k));
        if (av === bv) continue;
        if (av == null) return -dir;
        if (bv == null) return dir;
        return (av < bv ? -1 : 1) * dir;
    }
    return 0;
};
function parseSort(s) {
    if (!s) return [];
    if (typeof s === 'string') return s.split(/\s+/).filter(Boolean).map((k) => (k[0] === '-' ? [k.slice(1), -1] : [k.replace(/^\+/, ''), 1]));
    return Object.entries(s).map(([k, v]) => [k, v === 'desc' || v === 'descending' || Number(v) < 0 ? -1 : 1]);
}

class Query {
    constructor(model, op, filter, extra = {}) {
        this.model = model; this.op = op; this.filter = normalizeIds(filter || {});
        this._sort = []; this._skip = 0; this._limit = 0; this._select = null; this._lean = false;
        this._populate = []; this.extra = extra; this._update = extra.update && normalizeIds(extra.update);
    }
    sort(s) { this._sort = parseSort(s); return this; }
    skip(n) { this._skip = n; return this; }
    limit(n) { this._limit = n; return this; }
    select(s) { this._select = s; return this; }
    lean() { this._lean = true; return this; }
    // Model.find(filter).distinct(field), same as Model.distinct(field, filter).
    distinct(field) { this.op = 'distinct'; this.extra = { ...this.extra, field }; return this; }
    maxTimeMS() { return this; }
    populate(p, sel) {
        if (typeof p === 'string' && !sel) p.split(/\s+/).filter(Boolean).forEach((x) => this._populate.push({ path: x }));
        else if (typeof p === 'string') this._populate.push({ path: p, select: sel });
        else this._populate.push(...[].concat(p));
        return this;
    }
    getFilter() { return this.filter; }
    getUpdate() { return this._update; }
    exec() { return this.model._exec(this); }
    then(res, rej) { return this.exec().then(res, rej); }
    catch(rej) { return this.exec().catch(rej); }
    finally(f) { return this.exec().finally(f); }
}

// Apply select()/hidden-field rules to a stored object, returning a copy.
function projectDoc(model, raw, select) {
    const hidden = Object.entries(model.schema.paths).filter(([, i]) => i.selectFalse).map(([p]) => p);
    const tokens = !select ? [] : typeof select === 'string' ? select.split(/\s+/).filter(Boolean) : Object.entries(select).map(([k, v]) => (v ? k : '-' + k));
    const plus = tokens.filter((t) => t[0] === '+').map((t) => t.slice(1));
    const minus = tokens.filter((t) => t[0] === '-').map((t) => t.slice(1));
    const inc = tokens.filter((t) => t[0] !== '-' && t[0] !== '+');
    let out;
    if (inc.length) {
        out = {};
        if (!minus.includes('_id')) out._id = raw._id;
        for (const f of [...inc, ...plus]) { const v = getPath(raw, f); if (v !== undefined) setPath(out, f, clone(v)); }
    } else {
        out = clone(raw);
        for (const h of hidden) if (!plus.includes(h)) unsetPath(out, h);
        for (const m of minus) unsetPath(out, m);
    }
    return out;
}

class Model {
    constructor(name, schema) {
        this.modelName = name; this.schema = schema;
        this.collection = schema.opts.collection || name;
        const self = this;
        function Doc(data) { Object.assign(this, data); }
        Doc.prototype.save = async function () { return self._save(this); };
        Doc.prototype.toObject = function () { return clone({ ...this }); };
        Doc.prototype.toJSON = function () { return clone({ ...this }); };
        Doc.prototype.deleteOne = async function () { await self.deleteOne({ _id: this._id }); return this; };
        Doc.prototype.populate = async function (p) {
            await self._populateAll([this], typeof p === 'string' ? p.split(/\s+/).filter(Boolean).map((x) => ({ path: x })) : [].concat(p));
            return this;
        };
        Object.defineProperty(Doc.prototype, 'id', { get() { return this._id; }, enumerable: false });
        for (const [vn, fn] of Object.entries(schema.virtuals)) Object.defineProperty(Doc.prototype, vn, { get: fn, enumerable: false });
        this.Doc = Doc;
    }

    _hydrate(stored) {
        const raw = JSON.parse(stored);
        revive(this.schema.paths, raw);
        return raw;
    }
    _toDoc(raw) { return new this.Doc(raw); }

    async _rows(filter, { sort = [], skip = 0, limit = 0 } = {}) {
        const where = compileFilter(this.schema, filter);
        const exact = where !== null;
        const sortable = sort.every(([k]) => !k.includes('.') && !(this.schema.paths[k] && this.schema.paths[k].array));
        const pushSort = exact && sort.length > 0 && sortable;
        const pushPage = exact && (!sort.length || pushSort);
        let sql = `SELECT data FROM docs WHERE collection=${lit(this.collection)}`;
        if (exact) sql += ` AND (${where})`;
        if (pushSort) sql += ' ORDER BY ' + sort.map(([k, d]) => `${colFor(k)} ${d < 0 ? 'DESC' : 'ASC'}`).join(', ');
        if (pushPage && (limit || skip)) sql += ` LIMIT ${limit ? limit | 0 : -1} OFFSET ${skip | 0}`;
        const { results } = await D().prepare(sql).all();
        let docs = results.map((r) => this._hydrate(r.data));
        if (!exact) docs = docs.filter((d) => matches(d, filter));
        if (!pushPage) {
            if (sort.length) docs.sort(sortCmp(sort));
            if (skip || limit) docs = docs.slice(skip, limit ? skip + limit : undefined);
        }
        return docs;
    }

    async _populateAll(docs, pops) {
        for (const spec of pops) {
            const info = this.schema.paths[spec.path];
            const refName = (spec.model && (spec.model.modelName || spec.model)) || (info && info.ref);
            const target = registry.get(refName);
            if (!target) continue;
            const ids = new Set();
            for (const d of docs) {
                const v = getPath(d, spec.path);
                (Array.isArray(v) ? v : [v]).forEach((x) => x != null && ids.add(String(normId(x))));
            }
            if (!ids.size) continue;
            const found = new Map();
            const list = [...ids];
            for (let i = 0; i < list.length; i += 300) {
                const chunk = await target._rows({ _id: { $in: list.slice(i, i + 300) } });
                chunk.forEach((r) => found.set(r._id, r));
            }
            const put = (x) => {
                const r = found.get(String(normId(x)));
                if (!r || (spec.match && !matches(r, spec.match))) return undefined;
                return projectDoc(target, r, spec.select);
            };
            for (const d of docs) {
                const v = getPath(d, spec.path);
                if (v == null) continue;
                setPath(d, spec.path, Array.isArray(v) ? v.map(put).filter((x) => x !== undefined) : (put(v) ?? null));
            }
        }
        return docs;
    }

    async _exec(q) {
        switch (q.op) {
            case 'find': case 'findOne': {
                const one = q.op === 'findOne';
                const rows = await this._rows(q.filter, { sort: q._sort, skip: q._skip, limit: one ? 1 : q._limit });
                const slice = one ? rows.slice(0, 1) : rows;
                if (q._populate.length) await this._populateAll(slice, q._populate);
                const projected = slice.map((r) => {
                    const out = projectDoc(this, r, q._select);
                    for (const p of q._populate) { const v = getPath(r, p.path); if (v !== undefined) setPath(out, p.path, v); }
                    return out;
                });
                const out = q._lean ? projected : projected.map((r) => this._toDoc(r));
                return one ? out[0] || null : out;
            }
            case 'count': return this._count(q.filter);
            case 'distinct': {
                const rows = await this._rows(q.filter);
                const seen = new Map();
                rows.forEach((r) => { const v = getPath(r, q.extra.field); (Array.isArray(v) ? v : [v]).forEach((x) => x != null && seen.set(String(comparable(x)), x)); });
                return [...seen.values()];
            }
            case 'update': return this._casUpdate(q.filter, q._update, { upsert: q.extra.upsert, returnNew: q.extra.returnNew, many: !q.extra.one });
            case 'delete': return this._delete(q);
            default: throw new Error('bad op ' + q.op);
        }
    }

    async _count(filter) {
        const where = compileFilter(this.schema, filter);
        if (where !== null) {
            const r = await D().prepare(`SELECT COUNT(*) c FROM docs WHERE collection=${lit(this.collection)} AND (${where})`).first();
            return r.c;
        }
        return (await this._rows(filter)).length;
    }

    async _delete(q) {
        const rows = await this._rows(q.filter, q.extra.one ? { limit: 1 } : {});
        const hit = q.extra.one ? rows.slice(0, 1) : rows;
        const ids = hit.map((r) => r._id);
        for (let i = 0; i < ids.length; i += 200) {
            await D().prepare(`DELETE FROM docs WHERE collection=${lit(this.collection)} AND id IN (${ids.slice(i, i + 200).map(lit).join(',')})`).run();
        }
        return { deletedCount: ids.length, doc: hit[0] };
    }

    _applyUpdate(raw, update, inserting) {
        if (!Object.keys(update).some((k) => k.startsWith('$'))) { for (const [k, v] of Object.entries(update)) setPath(raw, k, clone(v)); return; }
        for (const [op, fields] of Object.entries(update)) {
            for (const [path, v] of Object.entries(fields || {})) {
                const cur = getPath(raw, path);
                switch (op) {
                    case '$set': setPath(raw, path, clone(v)); break;
                    case '$setOnInsert': if (inserting) setPath(raw, path, clone(v)); break;
                    case '$unset': unsetPath(raw, path); break;
                    case '$inc': setPath(raw, path, (Number(cur) || 0) + v); break;
                    case '$max': if (cur == null || comparable(v) > comparable(cur)) setPath(raw, path, v); break;
                    case '$min': if (cur == null || comparable(v) < comparable(cur)) setPath(raw, path, v); break;
                    case '$push': {
                        const arr = Array.isArray(cur) ? cur : [];
                        if (isPlain(v) && v.$each) arr.push(...clone(v.$each)); else arr.push(clone(v));
                        setPath(raw, path, arr); break;
                    }
                    case '$addToSet': {
                        const arr = Array.isArray(cur) ? cur : [];
                        (isPlain(v) && v.$each ? v.$each : [v]).forEach((it) => { if (!arr.some((x) => comparable(x) === comparable(it))) arr.push(it); });
                        setPath(raw, path, arr); break;
                    }
                    case '$pull':
                        if (Array.isArray(cur)) setPath(raw, path, cur.filter((x) => !(isPlain(v) ? (isOps(v) ? matchValue(x, v) : (isPlain(x) && matches(x, v))) : comparable(x) === comparable(v))));
                        break;
                    default: throw new Error(`Unsupported update operator ${op}`);
                }
            }
        }
    }

    async _runUpdateHooks(filter, update) {
        for (const h of this.schema.hooks.update) {
            await new Promise((resolve, reject) => h.call({ getUpdate: () => update, getFilter: () => filter }, (err) => (err ? reject(err) : resolve())));
        }
    }

    // Read-modify-write guarded by compare-and-swap on the stored JSON text, so
    // concurrent $inc / $push never lose an update. Retries a few times.
    async _casUpdate(filter, update, { upsert = false, returnNew = false, many = false } = {}) {
        await this._runUpdateHooks(filter, update);
        const where = compileFilter(this.schema, filter);
        let candidates = await this._candidates(filter, where, many ? 0 : 1);
        if (!candidates.length && upsert) {
            const raw = {};
            for (const [k, v] of Object.entries(filter)) if (!k.startsWith('$') && !isOps(v) && !k.includes('.')) raw[k] = clone(v);
            this._applyUpdate(raw, update, true);
            const prepared = this._prepare(raw);
            try {
                await this._insertRaw(prepared);
                return { matched: 0, upserted: prepared, docs: [] };
            } catch (e) {
                // Another request inserted the same unique key first: update that row instead.
                if (e.code !== 11000) throw e;
                candidates = await this._candidates(filter, where, many ? 0 : 1);
            }
        }
        const docs = [];
        let matched = 0;
        for (const cand of candidates) {
            let current = cand.stored;
            let done = false;
            for (let attempt = 0; attempt < 40 && !done; attempt++) {
                const raw = this._hydrate(current);
                const prior = clone(raw);
                this._applyUpdate(raw, update, false);
                if (this.schema.opts.timestamps !== false) raw.updatedAt = new Date();
                const next = JSON.stringify(toStored(raw));
                const res = await wrapDb(() => D().prepare('UPDATE docs SET data=? WHERE collection=? AND id=? AND data=?').bind(next, this.collection, cand.id, current).run());
                if (res.meta.changes) { matched++; docs.push(returnNew ? raw : prior); done = true; break; }
                const fresh = await D().prepare('SELECT data FROM docs WHERE collection=? AND id=?').bind(this.collection, cand.id).first();
                if (!fresh || !matches(this._hydrate(fresh.data), filter)) { done = true; break; } // row gone or no longer matches
                current = fresh.data;
                await new Promise((r) => setTimeout(r, Math.random() * 8 * (attempt + 1)));
            }
            if (!done) throw new Error(`Write conflict on ${this.collection}/${cand.id}`);
        }
        return { matched, docs };
    }

    async _candidates(filter, where, limit) {
        let sql = `SELECT id, data FROM docs WHERE collection=${lit(this.collection)}`;
        if (where !== null) sql += ` AND (${where})`;
        if (where !== null && limit) sql += ` LIMIT ${limit}`;
        const { results } = await D().prepare(sql).all();
        const out = [];
        for (const r of results) {
            if (where === null && !matches(this._hydrate(r.data), filter)) continue;
            out.push({ id: r.id, stored: r.data });
            if (limit && out.length >= limit) break;
        }
        return out;
    }

    async _insertRaw(raw) {
        const stored = JSON.stringify(toStored(raw));
        await wrapDb(() => D().prepare('INSERT INTO docs (collection,id,data) VALUES (?,?,?)').bind(this.collection, raw._id, stored).run());
    }

    _prepare(data) {
        const raw = clone(normalizeIds(data));
        applyDefaults(this.schema.paths, raw);
        raw._id = raw._id ? String(raw._id) : newId();
        if (this.schema.opts.timestamps !== false) {
            const now = new Date();
            raw.createdAt = raw.createdAt || now;
            raw.updatedAt = raw.updatedAt || now;
        }
        return raw;
    }

    async _runSaveHooks(doc) {
        for (const h of this.schema.hooks.save) {
            await new Promise((resolve, reject) => h.call(doc, (err) => (err ? reject(err) : resolve())));
        }
    }

    async _save(doc) {
        await this._runSaveHooks(doc);
        Object.assign(doc, normalizeIds({ ...doc }));
        if (this.schema.opts.timestamps !== false) doc.updatedAt = new Date();
        const stored = JSON.stringify(toStored({ ...doc }));
        const res = await wrapDb(() => D().prepare('UPDATE docs SET data=? WHERE collection=? AND id=?').bind(stored, this.collection, doc._id).run());
        if (!res.meta.changes) await this._insertRaw({ ...doc });
        return doc;
    }

    // ---- public API ----
    find(filter) { return new Query(this, 'find', filter); }
    findOne(filter) { return new Query(this, 'findOne', filter); }
    findById(id) { return new Query(this, 'findOne', { _id: normId(id) }); }
    countDocuments(filter) { return new Query(this, 'count', filter); }
    estimatedDocumentCount() { return new Query(this, 'count', {}); }
    distinct(field, filter) { return new Query(this, 'distinct', filter, { field }); }
    exists(filter) { return this.findOne(filter).select('_id').lean().then((d) => (d ? { _id: d._id } : null)); }
    deleteMany(filter) { return new Query(this, 'delete', filter, {}); }
    deleteOne(filter) { return new Query(this, 'delete', filter, { one: true }); }
    findByIdAndDelete(id) { return this.findOneAndDelete({ _id: normId(id) }); }
    findOneAndDelete(filter) {
        const q = new Query(this, 'delete', filter, { one: true });
        q.exec = async () => { const r = await this._delete(q); return r.doc ? this._toDoc(r.doc) : null; };
        return q;
    }
    updateOne(filter, update, opts = {}) {
        const q = new Query(this, 'update', filter, { update, one: true, upsert: opts.upsert });
        q.exec = async () => { const r = await this._exec(q); return { matchedCount: r.matched, modifiedCount: r.matched, upsertedCount: r.upserted ? 1 : 0, upsertedId: r.upserted && r.upserted._id }; };
        return q;
    }
    updateMany(filter, update, opts = {}) {
        const q = new Query(this, 'update', filter, { update, upsert: opts.upsert });
        q.exec = async () => { const r = await this._exec(q); return { matchedCount: r.matched, modifiedCount: r.matched }; };
        return q;
    }
    _fau(filter, update, opts = {}) {
        const q = new Query(this, 'update', filter, { update, one: true, upsert: opts.upsert, returnNew: !!(opts.new || opts.returnDocument === 'after') });
        q.exec = async () => {
            const r = await this._exec(q);
            const raw = r.upserted ? (q.extra.returnNew ? r.upserted : null) : r.docs[0];
            if (!raw) return null;
            const proj = projectDoc(this, raw, q._select);
            if (q._populate.length) await this._populateAll([proj], q._populate);
            return q._lean ? proj : this._toDoc(proj);
        };
        return q;
    }
    findOneAndUpdate(filter, update, opts) { return this._fau(filter, update, opts); }
    findByIdAndUpdate(id, update, opts) { return this._fau({ _id: normId(id) }, update, opts); }
    async create(data) {
        if (Array.isArray(data)) { const out = []; for (const d of data) out.push(await this.create(d)); return out; }
        const raw = this._prepare(data);
        const doc = this._toDoc(raw);
        await this._runSaveHooks(doc);
        await this._insertRaw(raw);
        return doc;
    }
    insertMany(list) { return this.create(list); }
    aggregate(pipeline) { return aggregate(this, pipeline); }
    // Model.populate(docOrDocs, 'path' | {path,select} | [..]) fills references in place.
    async populate(docs, p) {
        const list = [].concat(docs).filter(Boolean);
        const specs = typeof p === 'string' ? p.split(/\s+/).filter(Boolean).map((x) => ({ path: x })) : [].concat(p);
        await this._populateAll(list, specs);
        return docs;
    }
    async bulkWrite(ops) {
        for (const op of ops) {
            if (op.updateOne) await this.updateOne(op.updateOne.filter, op.updateOne.update, { upsert: op.updateOne.upsert });
            else if (op.insertOne) await this.create(op.insertOne.document);
            else if (op.deleteOne) await this.deleteOne(op.deleteOne.filter);
            else if (op.updateMany) await this.updateMany(op.updateMany.filter, op.updateMany.update);
            else throw new Error('Unsupported bulkWrite op');
        }
        return { ok: 1 };
    }
}

// ---- aggregation (the subset the app uses) -----------------------------------------

function evalExpr(e, doc) {
    if (typeof e === 'string' && e.startsWith('$')) return getPath(doc, e.slice(1));
    if (Array.isArray(e)) return e.map((x) => evalExpr(x, doc));
    if (!isPlain(e)) return e;
    const [op, arg] = Object.entries(e)[0] || [];
    if (!op || !op.startsWith('$')) { const o = {}; for (const [k, v] of Object.entries(e)) o[k] = evalExpr(v, doc); return o; }
    const a = Array.isArray(arg) ? arg.map((x) => evalExpr(x, doc)) : evalExpr(arg, doc);
    switch (op) {
        case '$ifNull': return a[0] != null ? a[0] : a[1];
        case '$cond': { const c = Array.isArray(arg) ? arg : [arg.if, arg.then, arg.else]; return evalExpr(c[0], doc) ? evalExpr(c[1], doc) : evalExpr(c[2], doc); }
        case '$size': return Array.isArray(a) ? a.length : 0;
        case '$eq': return comparable(a[0]) === comparable(a[1]);
        case '$ne': return comparable(a[0]) !== comparable(a[1]);
        case '$gt': return comparable(a[0]) > comparable(a[1]);
        case '$gte': return comparable(a[0]) >= comparable(a[1]);
        case '$lt': return comparable(a[0]) < comparable(a[1]);
        case '$lte': return comparable(a[0]) <= comparable(a[1]);
        case '$add': return a.reduce((s, x) => s + (Number(x) || 0), 0);
        case '$subtract': return a[0] - a[1];
        case '$multiply': return a.reduce((s, x) => s * x, 1);
        case '$divide': return a[0] / a[1];
        case '$toString': return a == null ? null : String(normId(a));
        case '$and': return a.every(Boolean);
        case '$or': return a.some(Boolean);
        case '$literal': return arg;
        case '$in': return Array.isArray(a[1]) && a[1].some((x) => comparable(x) === comparable(a[0]));
        case '$isArray': return Array.isArray(Array.isArray(arg) ? a[0] : a);
        case '$arrayElemAt': return Array.isArray(a[0]) ? a[0].at(a[1]) : undefined;
        case '$not': return !(Array.isArray(a) ? a[0] : a);
        case '$mod': return a[0] % a[1];
        case '$round': return Number(Number(a[0]).toFixed(a[1] || 0));
        case '$abs': return Math.abs(a);
        case '$concat': return a.join('');
        case '$toLower': return String(a).toLowerCase();
        case '$max': return Math.max(...[].concat(a));
        case '$min': return Math.min(...[].concat(a));
        default: throw new Error(`Unsupported aggregation expression ${op}`);
    }
}

async function aggregate(model, pipeline) {
    const stages = pipeline.map((s) => normalizeIds(s));
    let docs = await model._rows(stages[0] && stages[0].$match ? stages.shift().$match : {});
    for (const st of stages) {
        const [op, arg] = Object.entries(st)[0];
        if (op === '$match') docs = docs.filter((d) => matches(d, arg));
        else if (op === '$sort') docs = docs.slice().sort(sortCmp(parseSort(arg)));
        else if (op === '$limit') docs = docs.slice(0, arg);
        else if (op === '$skip') docs = docs.slice(arg);
        else if (op === '$count') docs = [{ [arg]: docs.length }];
        else if (op === '$unwind') {
            const path = (typeof arg === 'string' ? arg : arg.path).slice(1);
            docs = docs.flatMap((d) => { const v = getPath(d, path); return Array.isArray(v) ? v.map((x) => { const c = clone(d); setPath(c, path, x); return c; }) : []; });
        } else if (op === '$project' || op === '$addFields' || op === '$set') {
            docs = docs.map((d) => {
                const out = op === '$project' ? {} : { ...d };
                if (op === '$project' && arg._id !== 0) out._id = d._id;
                for (const [k, v] of Object.entries(arg)) {
                    if (k === '_id' && v === 0) continue;
                    if (v === 1 || v === true) out[k] = getPath(d, k); else if (v === 0 || v === false) delete out[k]; else out[k] = evalExpr(v, d);
                }
                return out;
            });
        } else if (op === '$group') {
            const groups = new Map();
            for (const d of docs) {
                const key = evalExpr(arg._id, d);
                const ks = JSON.stringify(key instanceof Date ? key.toISOString() : key);
                if (!groups.has(ks)) groups.set(ks, { key, docs: [] });
                groups.get(ks).docs.push(d);
            }
            docs = [...groups.values()].map(({ key, docs: g }) => {
                const out = { _id: key };
                for (const [f, acc] of Object.entries(arg)) {
                    if (f === '_id') continue;
                    const [aop, aexpr] = Object.entries(acc)[0];
                    const vals = g.map((d) => evalExpr(aexpr, d));
                    const nums = vals.filter((x) => typeof x === 'number');
                    switch (aop) {
                        case '$sum': out[f] = aexpr === 1 ? g.length : nums.reduce((s, x) => s + x, 0); break;
                        case '$avg': out[f] = nums.length ? nums.reduce((s, x) => s + x, 0) / nums.length : null; break;
                        case '$max': out[f] = vals.filter((x) => x != null).reduce((m, x) => (m == null || comparable(x) > comparable(m) ? x : m), null); break;
                        case '$min': out[f] = vals.filter((x) => x != null).reduce((m, x) => (m == null || comparable(x) < comparable(m) ? x : m), null); break;
                        case '$first': out[f] = vals[0]; break;
                        case '$last': out[f] = vals[vals.length - 1]; break;
                        case '$push': out[f] = vals; break;
                        case '$addToSet': out[f] = [...new Map(vals.map((x) => [String(comparable(x)), x])).values()]; break;
                        default: throw new Error(`Unsupported accumulator ${aop}`);
                    }
                }
                return out;
            });
        } else throw new Error(`Unsupported aggregation stage ${op}`);
    }
    return docs;
}

// ---- mongoose facade ---------------------------------------------------------------

function model(name, schema) {
    if (!schema) return registry.get(name + '#proxy');
    const m = new Model(name, schema);
    const proxy = new Proxy(function () {}, {
        get(_, prop) {
            if (prop === 'prototype') return m.Doc.prototype;
            const v = m[prop];
            return typeof v === 'function' ? v.bind(m) : v;
        },
        construct(_, args) { return m._toDoc(m._prepare(args[0] || {})); },
        apply(_, __, args) { return m._toDoc(m._prepare(args[0] || {})); }
    });
    registry.set(name, m);
    registry.set(name + '#proxy', proxy);
    return proxy;
}

const mongoose_noop = undefined;
const ObjectId = Object.assign(function (v) { return v ? String(normId(v)) : newId(); }, {
    isValid: (v) => isId(typeof v === 'string' ? v : v && v.toString ? v.toString() : '')
});

module.exports = {
    Schema,
    model,
    models: new Proxy({}, { get: (_, n) => registry.get(String(n) + '#proxy') }),
    Types: { ObjectId, Mixed: MixedType },
    connection: { get readyState() { return state.db ? 1 : 0; }, name: 'qspot' },
    isValidObjectId: ObjectId.isValid,
    connect: async () => mongoose_noop,
    disconnect: async () => {},
    // Worker glue
    __setDb(db) { state.db = db; },
    __db: () => D(),
    __registry: registry,
    __internals: { matches, compileFilter, aggregate, newId }
};
