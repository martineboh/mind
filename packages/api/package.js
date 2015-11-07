Package.describe({
  name: 'api',
  version: '0.1.0'
});

Npm.depends({
  'mime-types': '2.1.6'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'random'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:middleware@0.1.1',
    'peerlibrary:reactive-publish@0.1.1',
    'peerlibrary:check-extension@0.2.0',
    'peerlibrary:assert@0.2.5',
    'fermuch:cheerio@0.19.0',
    'peerlibrary:meteor-file@0.2.1'
  ]);

  // Internal dependencies.
  api.use([
    'core',
    'voting',
    'sanitize',
    'storage'
  ]);

  api.addFiles([
    'upvotable.coffee',
    'meeting/methods.coffee',
    'discussion/methods.coffee',
    'comment/methods.coffee',
    'point/methods.coffee',
    'motion/methods.coffee'
  ]);

  api.addFiles([
    'sanitize.coffee',
    'attachments.coffee',
    'meeting/publish.coffee',
    'discussion/publish.coffee',
    'comment/publish.coffee',
    'point/publish.coffee',
    'motion/publish.coffee',
    'storagefile/methods.coffee'
  ], 'server');
});
