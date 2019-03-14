/*
    Custom Element with Ace code editor
    based on
    http://juicy.github.io/juicy-ace-editor/
    version: 2.0.5
 */
require('ace-builds/src-min-noconflict/ace')
require('ace-builds/src-min-noconflict/ext-searchbox')
require('ace-builds/src-min-noconflict/ext-statusbar')
require('ace-builds/src-min-noconflict/ext-settings_menu')
require('ace-builds/src-min-noconflict/ext-language_tools')
require('ace-builds/src-min-noconflict/snippets/text')
require('ace-builds/src-min-noconflict/mode-sql')
require('ace-builds/src-min-noconflict/snippets/sql')
require('ace-builds/src-min-noconflict/mode-json')
require('ace-builds/src-min-noconflict/snippets/json')
require('ace-builds/src-min-noconflict/theme-dawn')
require('ace-builds/src-min-noconflict/ext-error_marker')

// In order for syntax validation to work you need to
// copy 'ace-builds/src-min-noconflict/worker-json.js'
// to the root of you static files 'client/assets/static/worker-json.js'
// so it should be accessible as https://loaclhost:3000/worker-json.js
// It required because Ace uses web workers for the validation


// Creates an object based in the HTML Element prototype
class AceEditor extends HTMLElement {
  // getter/setter for value property
  get value() {
    return this.editor && this.editor.getValue() || this.textContent
  }

  set value(val) {
    if (this.editor) {
      this.editor.setValue(val)
    } else {
      this.textContent = val
    }
  }

  // list of observable attributes
  static get observedAttributes() {
    return ['theme', 'mode', 'fontsize', 'softtabs', 'tabsize', 'readonly', 'wrapmode']
  }

  // Fires when an instance of the element is created
  constructor(self) {
    // Polyfill ceveat we need to fetch the right context;
    // https://github.com/WebReflection/document-register-element/tree/master#v1-caveat
    self = super(self)
    // Creates the shadow root
    let shadowRoot
    if (self.attachShadow && self.getRootNode) {
      shadowRoot = self.attachShadow({mode: 'open'})
    } else {
      shadowRoot = self.createShadowRoot()
    }

    shadowRoot.innerHTML = `
        <style>
        :host {
            display: flex;
            min-height: 1em;
            flex-direction: column;
            white-space: normal;
        }
        #ace-editor-container {
            flex: 1;
            height: 100%;
        }
        #ace-editor-status {                        
            position: relative;
            font-size: 0.7em;
            line-height: 1.5em;
            border-top: 1px solid #ebebeb;
            bottom: -5px;
        }
        .help {            
            position: absolute;
            right: 16px;       
            color: #0ba4cb;!important;     
        }
        
        </style>
        <div id="ace-editor-container">loading...</div>
        <div id="ace-editor-status">
            <a title="Keyboard Shortcuts" class="help" target="_blank" 
            href="https://github.com/ajaxorg/ace/wiki/Default-Keyboard-Shortcuts">Keys❓</a>
        </div>`


    self.container = shadowRoot.getElementById('ace-editor-container')
    self.statusBar = shadowRoot.getElementById('ace-editor-status')
    return self
  }

  connectedCallback() {
    const text = this.childNodes[0]
    const container = this.container
    const element = this
    let editor

    if (this.editor) {
      editor = this.editor
    } else {
      container.textContent = this.value
      editor = window.ace.edit(container)
      this.dispatchEvent(new CustomEvent('editor-ready', {bubbles: true, composed: true, detail: editor}))
      this.editor = editor

      // inject base editor styles
      this.injectTheme('#ace_editor\\.css')
      this.injectTheme('#ace-tm')
      this.injectTheme('#ace_searchbox')

      editor.getSession().on('change', function (event) {
        element.dispatchEvent(new CustomEvent('change', {bubbles: true, composed: true, detail: event}))
      })
    }

    // handle theme changes
    editor.renderer.addEventListener('themeLoaded', this.onThemeLoaded.bind(this))

    // initial attributes
    editor.setTheme(this.getAttribute('theme'))
    editor.setFontSize(parseInt(this.getAttribute('fontsize')) || 18)
    editor.setReadOnly(this.hasAttribute('readonly'))
    editor.setOptions({
      enableBasicAutocompletion: true,
      enableSnippets: true,
      enableLiveAutocompletion: true
    })
    const StatusBar = window.ace.require('ace/ext/statusbar').StatusBar
    // create a simple selection status indicator
    new StatusBar(editor, this.statusBar)

    const session = editor.getSession()
    session.setMode(this.getAttribute('mode'))
    session.setUseSoftTabs(this.getAttribute('softtabs'))
    this.getAttribute('tabsize') && session.setTabSize(+this.getAttribute('tabsize'))
    session.setUseWrapMode(this.hasAttribute('wrapmode'))


    // Observe input textNode changes
    // Could be buggy as editor was also added to Light DOM;
    const observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        if (mutation.type === 'characterData') {
          element.value = text.data
        }
      })
    })
    text && observer.observe(text, {characterData: true})
    this._attached = true
  }

  disconnectedCallback() {
    this._attached = false
  }

  attributeChangedCallback(attr, oldVal, newVal) {
    if (!this._attached) {
      return false
    }
    switch (attr) {
      case 'theme':
        this.editor.setTheme(newVal)
        break
      case 'mode':
        this.editor.getSession().setMode(newVal)
        break
      case 'fontsize':
        this.editor.setFontSize(newVal)
        break
      case 'softtabs':
        this.editor.getSession().setUseSoftTabs(newVal)
        break
      case 'tabsize':
        this.editor.getSession().setTabSize(newVal)
        break
      case 'readonly':
        this.editor.setReadOnly(newVal === '' || newVal)
        break
      case 'wrapmode':
        this.editor.getSession().setUseWrapMode(newVal !== null)
        break

    }
  }

  onThemeLoaded(e) {
    const themeId = '#' + e.theme.cssClass
    this.injectTheme(themeId)
    // Workaround Chrome stable bug, force repaint
    this.container.style.display = 'none'
    this.container.offsetHeight
    this.container.style.display = ''
  }

  injectTheme(themeId) {
    const n = document.querySelector(themeId)
    this.shadowRoot.appendChild(cloneStyle(n))
  }
}

//helper function to clone a style
function cloneStyle(style) {
  const s = document.createElement('style')
  s.id = style.id
  s.textContent = style.textContent
  return s
}

window.customElements.define('ace-editor', AceEditor)
