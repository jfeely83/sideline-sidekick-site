#!/bin/zsh
# Site health: tag balance, internal links, stale prices, nav consistency.
#
# Written after a $99 survived three rounds of updates because every grep had
# looked at public/*.html and missed public/guides/. Whatever this checks, it
# checks EVERY page under public/ — the bug was never the pattern, it was the
# path.
set -uo pipefail
cd "$(dirname "$0")"
FAIL=0
say() { echo "$@"; }

say "── pages ──"
PAGES=$(find public -name '*.html' | wc -l | tr -d ' ')
say "  $PAGES html files under public/"

say "── tag balance ──"
python3 - <<'PY' || FAIL=1
import glob, sys
from html.parser import HTMLParser
VOID = {"meta","br","img","link","hr","input","source","area","base","col","embed","param","track","wbr"}
bad = 0
for f in sorted(glob.glob("public/**/*.html", recursive=True)):
    class P(HTMLParser):
        def __init__(self): super().__init__(); self.stack=[]
        def handle_starttag(self,t,a):
            if t not in VOID: self.stack.append(t)
        def handle_endtag(self,t):
            if self.stack and self.stack[-1]==t: self.stack.pop()
            elif t in self.stack:
                while self.stack and self.stack.pop()!=t: pass
    p=P(); p.feed(open(f).read())
    if p.stack:
        print(f"  UNBALANCED {f}: {p.stack[-4:]}"); bad+=1
print(f"  {bad} unbalanced" if bad else "  all balanced")
sys.exit(1 if bad else 0)
PY

say "── internal links resolve ──"
python3 - <<'PY' || FAIL=1
import glob, re, os, sys
broken = 0
pages = {f.replace("public","",1) for f in glob.glob("public/**/*.html", recursive=True)}
def exists(href):
    h = href.split("#")[0].split("?")[0]
    if not h or h == "/": return True
    if h.endswith("/"): h += "index.html"
    if h in pages: return True
    if h + ".html" in pages: return True
    if h + "/index.html" in pages: return True
    return os.path.exists("public" + h)
for f in sorted(glob.glob("public/**/*.html", recursive=True)):
    for href in re.findall(r'href="(/[^"]*)"', open(f).read()):
        if not exists(href):
            print(f"  BROKEN {f.replace('public/','')} -> {href}"); broken += 1
print(f"  {broken} broken" if broken else "  all internal links resolve")
sys.exit(1 if broken else 0)
PY

say "── referenced assets exist ──"
python3 - <<'PY' || FAIL=1
import glob, re, os, sys
# The link check above covers href=, so <a> and <link rel=preload>. It does not
# cover src=, poster=, or url() inside the stylesheet -- and url() is where the
# font is referenced. An asset referenced but absent used to fail silently:
# with no 404.html, Pages' SPA fallback answered every miss with the home page
# at 200, so a status-code check downstream could not see it. There is a real
# 404 now, but a missing file is still cheaper to catch here than in a browser.
missing = 0
refs = []
for f in sorted(glob.glob("public/**/*.html", recursive=True)):
    s = open(f).read()
    for m in re.findall(r'(?:src|poster)="(/[^"]*)"', s):
        refs.append((f, m))
for f in sorted(glob.glob("public/**/*.css", recursive=True)):
    s = open(f).read()
    for m in re.findall(r"""url\(\s*['"]?(/[^)'"]*)""", s):
        refs.append((f, m))
for f, r in refs:
    path = "public" + r.split("#")[0].split("?")[0]
    if not os.path.isfile(path):
        print(f"  MISSING {f.replace('public/','')} -> {r}"); missing += 1
print(f"  {missing} missing" if missing else f"  all {len(refs)} referenced assets exist on disk")
sys.exit(1 if missing else 0)
PY

say "── stale prices in VISIBLE copy ──"
python3 - <<'PY' || FAIL=1
import glob, re, sys
hits = 0
for f in sorted(glob.glob("public/**/*.html", recursive=True)):
    v = re.sub(r'<!--.*?-->', '', open(f).read(), flags=re.S)
    t = re.sub(r'<[^>]+>', ' ', v)
    for line in t.split("\n"):
        # $100 in terms.html is the liability cap, not a price.
        if re.search(r'\$\s?\d', line) and "capped at" not in line and "($100)" not in line:
            print(f"  PRICE {f.replace('public/','')}: {line.strip()[:80]}"); hits += 1
print(f"  {hits} price statements" if hits else "  no price stated anywhere (deferred to the App Store)")
sys.exit(1 if hits else 0)
PY

say "── nav consistency ──"
python3 - <<'PY'
import glob, re, collections
navs = collections.Counter()
for f in sorted(glob.glob("public/**/*.html", recursive=True)):
    s = open(f).read()
    links = tuple(sorted(set(re.findall(r'<a href="(/[a-z-]*)"[^>]*>[^<]*</a>', s))))
    navs[links] += 1
top, n = navs.most_common(1)[0]
print(f"  most common link set appears on {n} of {sum(navs.values())} pages")
for links, c in navs.most_common()[1:4]:
    missing = set(top) - set(links)
    if missing: print(f"    {c} page(s) missing: {sorted(missing)}")
PY

say ""
[[ $FAIL -eq 0 ]] && say "ALL CHECKS PASSED" || say "SOME CHECKS FAILED (above)"
exit $FAIL
