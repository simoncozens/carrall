module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    coffee: {
      compile: {
        options: { bare: "true" },
        files: {
          "src/carrall.js" : "coffee/**/*"
        }
      }
    },
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
      },
      dist: {
        files: {
          'carrall.min.js': 'src/carrall.js'
        }
      }
    },
    exec: {
      make_index: {
        cmd: "grep -v '^    ' coffee/carrall.litcoffee | uniq > README.md"
      }
    }
  })
  // Load the plugin that provides the "uglify" task.
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-exec');
  // Default task(s).
  grunt.registerTask('default', ['coffee', 'uglify', 'exec']);
}
