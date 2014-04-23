module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      options:
        sourceMap: true
      build:
        files:
          'webfft.js': ['webfft.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'default', ['coffee']
