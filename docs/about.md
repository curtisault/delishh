---
tag: ABOUT
kicker: DELISHH COLOPHON
rev: REV 2
revDate: 2026-09-20
titleLines: [About]
standfirst: >-
  What this is, what it is built from, and what is never kept about
  anyone who reads it.
footNote: >-
  This page is generated from docs/about.md. The design it describes
  is set out in full in the standard.
---

# About delishh

Document · Revision 2 · Issued 2026-09-20

*Everything above the first `##` is the header of the raw file. The
app takes its masthead from the frontmatter, so this preamble is not
rendered — and the two must be kept in step by hand.*

---

## 00. What this is
<!-- doc anchor=sec-who toc="What this is" intent="A personal archive, not a publication" body=clauses -->

delishh is one person's recipe archive. It exists to keep recipes, to
find them again, and to print them — and it is built for the person
who cooks from it rather than for anyone arriving from a search
engine.

That distinction decides almost everything about it. There is no
origin story above a recipe, because you already know why you saved
it. There is no rating and no comment thread, because the only
opinion that matters is recorded in the note at the bottom of each
document. **Recipes carry what goes wrong**, which is the block most
recipe sites omit and the main reason this one was built.

Every recipe is one markdown file. The site is generated from those
files, and a recipe that fails the schema fails the build rather than
appearing half-rendered — so the archive is either right or it does
not ship.

The author is whoever keeps it. A document with no author is a
document nobody can question.

---

## 01. How it is made
<!-- doc anchor=sec-colophon toc="Colophon" intent="Type, tooling, and what is never kept" body=clauses -->

Elm, compiled by Vite, served as static files. Deno is the only
JavaScript runtime in the toolchain; there is no Node anywhere in the
build. Recipes are markdown parsed into JSON at build time, and the
prose documents — this page among them — are markdown compiled
straight into the application.

### The four voices

Type does real work here: a glyph's typeface tells you what *kind* of
information it is, every time.

| Voice | Face | Carries |
|-------|------|---------|
| Display | Archivo Expanded 700 | Titles, plates, labels |
| Body | Inter 500 | Every word read while cooking |
| Data | JetBrains Mono 400/700 | Every number that means something |
| Human | Instrument Serif 400 | The note at the foot of a recipe, and nothing else |

All four are self-hosted under the SIL Open Font License, with their
licence texts shipped beside them. Nothing is fetched from a font
CDN, and nothing is fetched from anywhere else either.

### What is kept about you

Nothing. There is no analytics, no tracking, no error reporting and
no third-party script of any kind on this site.

**Two things are stored in this browser**, each under a single key.
The first is which lighting you chose, so the page does not flash the
wrong theme before it loads; choosing "System" clears it. The second
is your shopping list — the recipes you added to it and the items you
have ticked off — so it is still there when you get to the shop.
Taking the last recipe back off the list clears that one.

Nothing is sent anywhere, and there is no server to send it to — the
whole site is static files. Both keys are local to this browser, so
the list does not follow you to another device, and clearing your
site data ends both.

### Checks that run on every build

The unusual ones, because they are the reason the archive can be
trusted:

- Every recipe is validated against the schema, with closed
  vocabularies. A misspelled flavour fails the build.
- Every colour pair is recomputed for contrast in both themes, and a
  ratio written in a comment is held to the hex beside it.
- The print stylesheet is read for greyscale-only colour and its type
  floors, because print is the one surface nobody looks at.
- The word rules run against procedure — but never against the note,
  which is exempt on purpose.
