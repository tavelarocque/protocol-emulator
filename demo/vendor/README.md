# What the demo page carries inside itself

`docs/demo.html` is one file that fetches nothing, so the two things it
did not write are copied here and put into it by `bin/demo_traces.ml`.

| File | What | Version | Licence |
|---|---|---|---|
| `three.module.min.js` | three.js, the 3D library Figure 1 is drawn with | r170, `build/three.module.min.js` from the npm package `three@0.170.0`, unchanged | MIT, `three.LICENSE` |
| `plex.css` | IBM Plex Sans 400 and 600, Sans Condensed 500, Mono 400 and 600, Latin subset | the `.woff2` files of the npm packages `@fontsource/ibm-plex-sans`, `-sans-condensed` and `-mono`, 5.1.1 | SIL Open Font License 1.1, `IBM-Plex-LICENSE.txt` |

`plex.css` is five `@font-face` rules, each with its `.woff2` file as a
base64 `data:` URL:

```
for each face:  base64 -w0 files/<family>-latin-<weight>-normal.woff2
@font-face{font-family:"Plex Sans";font-style:normal;font-weight:400;font-display:block;
           src:url(data:font/woff2;base64,...) format("woff2")}
```

The families are named "Plex Sans", "Plex Sans Condensed" and "Plex Mono"
in the page, so that a copy of IBM Plex installed on the reader's machine
is never used in place of the one carried here.
