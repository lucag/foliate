# Foliate

An e-book reader: a native application wrapped around a web-based book renderer.

## Language

**Renderer**:
foliate-js, the web code that parses books (EPUB, MOBI, FB2, CBZ, PDF) and lays them out for reading inside a web view.
_Avoid_: engine, viewer

**Shell**:
The native application hosting the Renderer: windows, library, settings, file access and platform integration. On Linux it is the GJS/GTK app; a platform port may supply a different Shell around the same Renderer.
_Avoid_: frontend, wrapper, host app

**Reader page**:
The web page, shared by every Shell, that loads the Renderer and is the Shell's only channel to it.
_Avoid_: reader view, webview page

**Default text size**:
The text size every book opens at unless it has a Book text size of its own. One value for the whole app, set in the preferences.
_Avoid_: global font size, zoom

**Book text size**:
A text size the reader chose for one particular book, overriding the Default text size for that book only. Resetting it returns the book to the Default text size.
_Avoid_: zoom, per-book zoom
