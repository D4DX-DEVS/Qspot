const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizePhone, phoneError } = require('../services/phone');

test('an Indian number is saved as its 10 digits however it is typed', () => {
    for (const typed of ['9876543210', '+91 98765 43210', '+91 098765-43210', '098765 43210', '919876543210']) {
        assert.equal(normalizePhone(typed), '9876543210', typed);
    }
    assert.equal(phoneError('9876543210'), null);
});

test('a number from another country keeps its country code', () => {
    assert.equal(normalizePhone('+44 07400 123456'), '+447400123456', 'UK drops the leading 0');
    assert.equal(normalizePhone('+447400123456'), '+447400123456');
    assert.equal(normalizePhone('+971 50 123 4567'), '+971501234567');
    assert.equal(normalizePhone('+1 (201) 555-0123'), '+12015550123');
    assert.equal(normalizePhone('+225 07 12 34 56 78'), '+2250712345678', "Côte d'Ivoire keeps its 0");
});

test('each country has its own number of digits', () => {
    assert.equal(phoneError(normalizePhone('+971501234567')), null, 'UAE 9 digits');
    assert.equal(phoneError(normalizePhone('+9715012345678')), 'Enter a valid 9-digit phone number');
    assert.equal(phoneError(normalizePhone('+12015550123')), null, 'US 10 digits');
    assert.equal(phoneError(normalizePhone('+97433123456')), null, 'Qatar 8 digits');
    assert.equal(phoneError(normalizePhone('+4915123456789')), null, 'Germany 11 digits');
    assert.equal(phoneError(normalizePhone('+491512345678')), null, 'Germany 10 digits');
    assert.equal(phoneError(normalizePhone('+49151234567')), 'Enter a valid 10 or 11-digit phone number');
    assert.equal(phoneError(normalizePhone('+43664123')), 'Enter a valid 7 to 13-digit phone number', 'Austria');
});

test('a wrong Indian length or an unknown country code is refused', () => {
    assert.equal(phoneError(normalizePhone('+91 98765')), 'Enter a valid 10-digit phone number');
    assert.equal(phoneError(normalizePhone('+91 98765 432101')), 'Enter a valid 10-digit phone number');
    assert.equal(phoneError(normalizePhone('12345')), 'Enter a valid 10-digit phone number');
    assert.equal(phoneError(normalizePhone('')), 'Enter a valid 10-digit phone number');
    assert.equal(phoneError(normalizePhone('+999 1234567')), 'Enter a valid phone number with its country code');
    assert.equal(phoneError(normalizePhone('+')), 'Enter a valid phone number with its country code');
});
