module.exports = function (grunt) {
    grunt.initConfig({

    // define source files and their destinations
    uglify: {
        files: {
            src: 'ace-src/*.js',  // source files mask
            dest: 'ace/',    // destination folder
            expand: true,    // allow dynamic building
            flatten: true   // remove all unnecessary nesting
        }
    },
    watch: {
        js:  { files: 'ace-src/*.js', tasks: [ 'uglify' ] },
    }
});

// load plugins
grunt.loadNpmTasks('grunt-contrib-watch');
grunt.loadNpmTasks('grunt-contrib-uglify');

// register at least this one task
grunt.registerTask('default', [ 'uglify' ]);

};
