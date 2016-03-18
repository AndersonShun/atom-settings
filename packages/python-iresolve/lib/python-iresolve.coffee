{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'
{BufferedProcess} = require 'atom'
$ = require 'jquery'

module.exports =
class PythonIresolve
  constructor: ->
    @messages = new MessagePanelView
      title: 'Unresolved imports'

    @importData = {}

  checkForPythonContext: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor?
      return false
    return editor.getGrammar().name == 'Python'

  getFilePath: ->
    editor = atom.workspace.getActiveTextEditor()
    return editor.getPath()

  runCommand: ->
    filePath = @getFilePath()
    new Promise (resolve, reject) ->
      data = null
      console.log 'gole', atom.config.get 'python-iresolve.iresolveExecutablePath'
      process = new BufferedProcess
        command: atom.config.get 'python-iresolve.iresolveExecutablePath'
        args: ['--format=json', filePath]
        stdout: (out) -> data = out
        exit: =>
          console.log 'exit', data
          resolve data

      process.onWillThrowError ({handle}) ->
        handle()
        resolve()

  check: ->
    if not @checkForPythonContext()
      return

    self = this
    @runCommand().then (data) ->
      if not data or $.isEmptyObject(data)
        self.messages.close()
        self.messages.clear()
        return

      data = JSON.parse data
      self.importData[self.getFilePath()] = data
      self.reloadPanel()

  linkClicked: (evt) ->
    editor = atom.workspace.getActiveTextEditor()
    target = $(evt.target)
    mod = target.html()
    obj = target.attr('data-obj')
    curpos = editor.getCursorBufferPosition()
    editor.setCursorBufferPosition([1,0])
    editor.insertNewline()
    editor.insertText('from ' + mod + ' import ' + obj)
    editor.setCursorBufferPosition(curpos)
    editor.save()

  reloadPanel: ->
    @messages.clear()
    @messages.close()
    editor = atom.workspace.getActiveTextEditor()
    if not editor
      return

    data = @importData[@getFilePath()]
    if not data or $.isEmptyObject(data)
      return

    @messages.attach()
    for u, meta of data
      path_elems = []
      for path in meta.paths
        path_elems.push('<a data-obj="' + u + '">' + path + '</a>')

      msg = '<b>' + u + '</b> import from: ' + path_elems.join(' ')
      @messages.add new PlainMessageView
        raw: true
        message: msg

    _this = this
    @messages.body.find('a').click (evt) ->
      _this.linkClicked(evt)
      _this.messages.clear()
      _this.messages.close()
