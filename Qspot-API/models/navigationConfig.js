const mongoose = require('mongoose');

const navigationItemSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      enum: ['today', 'learn', 'practice', 'progress', 'me'],
      required: true,
    },
    visible: { type: Boolean, default: true },
    order: { type: Number, min: 0, default: 0 },
  },
  { _id: false }
);

const homeSectionSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      enum: [
        'hero',
        'banners',
        'stats',
        'shortcuts',
        'attention',
        'todo',
        'jumpBackIn',
        'comingUp',
        'subjects',
      ],
      required: true,
    },
    visible: { type: Boolean, default: true },
    order: { type: Number, min: 0, default: 0 },
  },
  { _id: false }
);

const navigationConfigSchema = new mongoose.Schema(
  {
    // There is one learner navigation configuration for the whole app.
    key: { type: String, unique: true, default: 'learner-primary' },
    items: { type: [navigationItemSchema], default: [] },
    homeSections: { type: [homeSectionSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('navigationConfig', navigationConfigSchema);
