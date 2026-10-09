const express = require('express');
const NavigationConfig = require('../models/navigationConfig');
const { authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();
const adminRouter = express.Router();

const DEFAULT_ITEMS = [
  { key: 'today', visible: true, order: 0 },
  { key: 'learn', visible: true, order: 1 },
  { key: 'practice', visible: true, order: 2 },
  { key: 'progress', visible: true, order: 3 },
  { key: 'me', visible: true, order: 4 },
];

const DEFAULT_HOME_SECTIONS = [
  'hero',
  'banners',
  'stats',
  'shortcuts',
  'attention',
  'todo',
  'jumpBackIn',
  'comingUp',
  'subjects',
].map((key, order) => ({ key, visible: true, order }));

const KEYS = new Set(DEFAULT_ITEMS.map((item) => item.key));
const HOME_SECTION_KEYS = new Set(DEFAULT_HOME_SECTIONS.map((item) => item.key));

const sortedItems = (items) => [...items].sort((a, b) => a.order - b.order);

const publicConfig = (config) => ({
  key: 'learner-primary',
  items: sortedItems(config?.items?.length ? config.items : DEFAULT_ITEMS).map((item) => ({
    key: item.key,
    visible: item.key === 'today' || item.visible !== false,
    order: item.order,
  })),
  homeSections: sortedItems(config?.homeSections?.length ? config.homeSections : DEFAULT_HOME_SECTIONS).map((item) => ({
    key: item.key,
    visible: item.visible !== false,
    order: item.order,
  })),
  updatedAt: config?.updatedAt || null,
});

const normaliseItems = (items) => {
  if (!Array.isArray(items)) {
    const error = new Error('items must be an array');
    error.status = 400;
    throw error;
  }

  const seen = new Set();
  const parsed = items.map((item, index) => {
    const key = String(item?.key || '').trim().toLowerCase();
    if (!KEYS.has(key)) {
      const error = new Error(`Unsupported navigation item: ${key || '(empty)'}`);
      error.status = 400;
      throw error;
    }
    if (seen.has(key)) {
      const error = new Error(`Duplicate navigation item: ${key}`);
      error.status = 400;
      throw error;
    }
    seen.add(key);
    return {
      key,
      visible: key === 'today' || item?.visible !== false,
      order: Number.isFinite(Number(item?.order)) ? Number(item.order) : index,
    };
  });

  // Today is the safe landing page and cannot be hidden. Without it a stale
  // client can boot into an empty shell after an admin changes the menu.
  if (!parsed.some((item) => item.key === 'today')) {
    parsed.push({ key: 'today', visible: true, order: -1 });
  }

  return sortedItems(parsed).map((item, index) => ({ ...item, order: index }));
};

const normaliseHomeSections = (sections) => {
  if (!Array.isArray(sections)) {
    const error = new Error('homeSections must be an array');
    error.status = 400;
    throw error;
  }

  const seen = new Set();
  const parsed = sections.map((item, index) => {
    const key = String(item?.key || '').trim();
    if (!HOME_SECTION_KEYS.has(key)) {
      const error = new Error(`Unsupported home section: ${key || '(empty)'}`);
      error.status = 400;
      throw error;
    }
    if (seen.has(key)) {
      const error = new Error(`Duplicate home section: ${key}`);
      error.status = 400;
      throw error;
    }
    seen.add(key);
    return {
      key,
      visible: item?.visible !== false,
      order: Number.isFinite(Number(item?.order)) ? Number(item.order) : index,
    };
  });

  return sortedItems(parsed).map((item, index) => ({ ...item, order: index }));
};

router.get('/', async (req, res) => {
  try {
    const config = await NavigationConfig.findOne({ key: 'learner-primary' }).lean();
    res.json(publicConfig(config));
  } catch (error) {
    console.error('Error fetching navigation config:', error);
    // The app has a client-side default too, so a config outage does not take
    // down the learner shell.
    res.json(publicConfig(null));
  }
});

adminRouter.get('/', authenticateAdmin, async (req, res) => {
  try {
    const config = await NavigationConfig.findOne({ key: 'learner-primary' }).lean();
    res.json(publicConfig(config));
  } catch (error) {
    console.error('Error fetching admin navigation config:', error);
    res.status(500).json({ message: 'Failed to fetch navigation config' });
  }
});

adminRouter.put('/', authenticateAdmin, async (req, res) => {
  try {
    const items = normaliseItems(req.body?.items);
    const homeSections = normaliseHomeSections(req.body?.homeSections);
    const config = await NavigationConfig.findOneAndUpdate(
      { key: 'learner-primary' },
      { $set: { items, homeSections }, $setOnInsert: { key: 'learner-primary' } },
      { new: true, upsert: true, runValidators: true }
    ).lean();
    res.json(publicConfig(config));
  } catch (error) {
    const status = error.status || (error.name === 'ValidationError' ? 400 : 500);
    if (status >= 500) console.error('Error updating navigation config:', error);
    res.status(status).json({ message: status === 500 ? 'Failed to update navigation config' : error.message });
  }
});

module.exports = { publicRouter: router, adminRouter };
