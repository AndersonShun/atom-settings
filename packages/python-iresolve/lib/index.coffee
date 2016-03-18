PythonIresolve = require './python-iresolve'

module.exports =
  config:
    iresolveExecutablePath:
      type: 'string'
      default: 'iresolve'
    checkOnSave:
      type: 'boolean'
      default: true

  activate: (state) ->
    pi = new PythonIresolve()

    atom.config.observe 'python-iresolve.checkOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value == true
          editor._iresolve = editor.onDidSave -> pi.check()
        else
          editor._iresolve?.dispose()

    atom.workspace.onDidChangeActivePaneItem (item) -> pi.reloadPanel()

  deactivate: ->
