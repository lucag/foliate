# Foliate

An e-book reader: a native application wrapped around a web-based book renderer.

## Language

**Renderer**:
foliate-js, the web code that parses books (EPUB, MOBI, FB2, CBZ, PDF) and lays them out for reading inside a web view.
_Avoid_: engine, viewer

**Shell**:
The native application hosting the Renderer: windows, library, settings, file access and platform integration. On Linux it is the GJS/GTK app; a platform port may supply a different Shell around the same Renderer.
_Avoid_: frontend, wrapper, host app
