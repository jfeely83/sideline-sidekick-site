# Deploying sideline-sidekick.com

The site is a **Cloudflare Pages** project connected to this GitHub repo. Everything
served to the public lives in `public/`. There is no build step and no framework.

## Deploy

Commit to `main` and push:

```sh
git add -A
git commit -m "..."
git push
```

That is the whole deploy. Pages watches `main`, runs no build command, and publishes
the contents of `public/` to sideline-sidekick.com. A build takes about a minute.

Check the result at https://sideline-sidekick.com, or list recent builds with:

```sh
npx wrangler pages deployment list --project-name sideline-sidekick-site
```

There is no separate publish step and nothing to run by hand. Do not use
`wrangler deploy` — that is the Workers command, and this site is not a Worker. This
account has exactly one Pages project and no Workers; if a second thing by a similar
name ever appears, it is not what serves the domain.

## Preview locally

```sh
npm install          # first time only, installs wrangler
npm run dev          # serves public/ the way Pages does
```

Extensionless paths behave the same locally as in production, so `/faq` and
`/support` resolve without the `.html`.

## What is in public/

| File           | Route      | Notes                                        |
|----------------|------------|----------------------------------------------|
| `index.html`   | `/`        | Home page                                    |
| `faq.html`     | `/faq`     | Coach's FAQ                                  |
| `support.html` | `/support` | Support                                      |
| `privacy.html` | `/privacy` | Privacy policy for the tracker                |
| `headset-privacy.html` | `/headset-privacy` | Privacy policy for Sideline Headset, a separate app |
| `styles.css`   |            | One stylesheet for every page                |
| `logo.png`     |            | Header mark and favicon, 96px                |
| `404.html`     |            | Served with a 404 for anything that does not match a file |

## Unknown paths

Anything that does not match a real file gets `public/404.html` with a **404**. Pages
walks up the directory tree for the closest `404.html`, so that one file covers
`/guides/` and every other subdirectory too.

**This changed on 2026-09-07, and the reason it changed is worth reading before
touching it.** `public/_redirects` used to hold one rule:

```
/* /index.html 200
```

The rule never did anything. The Pages `_redirects` parser rejects it outright —
`wrangler pages dev` reports `Infinite loop detected in this rule and has been ignored`
and `Parsed 0 valid redirect rules`, because rewriting to `/index.html` re-enters the
same rule once Pages strips `/index`. Put a rule beside it that is *not* a loop
(`/zzz-probe /faq 200`) and the parser reports `Parsed 1 valid redirect rule` and
serves it, while the catch-all stays ignored — the parser was fine, the rule was not.

What actually served the home page on every miss was Cloudflare's **default
single-page-application behaviour**, which is on whenever the output directory has no
top-level `404.html`: Pages "matches all incoming paths to the root (`/`)". Serving
`public/` with the `_redirects` file present and with it deleted produced byte-identical
responses on every path tested. The rule was inert; deleting it changed nothing.

That default was costing two things:

1. **A missing asset failed silently.** A stylesheet, image or font that had not
   deployed came back `200 text/html`, the browser discarded it, and no status-code
   check could see the difference. Verified 2026-09-07 against
   `/fonts/archivo-latin-var.woff2` before it went live.
2. **Every nonexistent URL was a 200 duplicate of the home page**, so crawlers saw
   unlimited duplicate content.

Both are gone now: a miss is a real 404, so a status check against the live site means
something, and `check-site.sh` has a `referenced assets exist` section that catches an
absent file before it is ever deployed.

`404.html` takes precedence over SPA mode, which is the whole mechanism — so **deleting
`public/404.html` silently restores the 200-on-everything behaviour.** That is what the
old note in this file warned against doing, on the mistaken belief that the `_redirects`
rule was producing the fallback. Keep the file.

### What Pages does natively, with no configuration

None of this needs a `_redirects` file. Verified 2026-09-07 on the live site and against
`wrangler pages dev public`:

- **Clean URLs.** `/faq`, `/support`, `/guides/plays` serve `faq.html`, `support.html`,
  `guides/plays.html`. All 16 pages verified byte-identical to the file on disk.
- **Canonical redirects, 308.** `/faq.html` → `/faq`, `/index.html` → `/`,
  `/guides/index.html` → `/guides/`, `/guides` → `/guides/`.
- **Assets win over everything.** All 39 files under `public/` — css, png, woff2, mp4,
  in subdirectories included — serve byte-identical with the right `Content-Type`.

## Colors

Every color is a custom property at the top of `styles.css`, sampled from the logo
(`SideKick-1024/sidekick-1024-lockup.png`): navy `#0C243C` and `#0C3C60`, red accent
`#B43C24`, cream wash `#FAF6EC`. Every foreground/background pairing in that block
meets WCAG AA (4.5:1). Changing `--accent` and `--accent-ink` rebrands the whole site;
re-check contrast if you do.

## The call-to-action buttons

Both primary CTAs on the home page are `mailto:support@sideline-sidekick.com` links,
and that is **deliberate**. The beta is closed and each coach is vetted by hand before
an invite goes out, so the button starts an email rather than dropping someone into
TestFlight. This is not an oversight — leave it alone unless the beta opens up.

## Email

`support@sideline-sidekick.com` — every CTA on the site is a `mailto:` to it — is
delivered by **Cloudflare Email Routing**, which is inbound forwarding only. Nothing
legitimately *sends* as this domain. Verified 2026-08-12: MX points at
`route1/2/3.mx.cloudflare.net` and SPF is published as
`v=spf1 include:_spf.mx.cloudflare.net ~all`.

**DMARC was added 2026-08-12** — a TXT record on `_dmarc` reading:

```
v=DMARC1; p=none; rua=mailto:support@sideline-sidekick.com
```

`p=none` is monitoring only: nothing gets blocked, and the aggregate reports go to
`support@` showing who is sending as the domain. Since nothing legitimately sends as it,
`p=reject` is the correct end state — move there once a month of reports comes back
clean. Reports arrive as XML attachments, roughly one a day per reporting provider, and
they land in the same inbox as the beta requests.

## www

`www.sideline-sidekick.com` was added 2026-08-12 and redirects to the apex. It is two
pieces, and it does not work with only one of them:

1. A **proxied CNAME** `www` → `sideline-sidekick.com`. Proxied is load-bearing: it is
   what puts the hostname on Cloudflare's edge so a rule can act on it. The DNS record
   on its own returns **522** — the edge has nothing that answers for the `www` Host
   header, because the Pages project's custom domain is the apex.
2. A **Redirect Rule**, "Redirect from WWW to root [Template]", matching
   `https://www.*` → `https://${1}` with a 301 and *Preserve query string* on (the
   template leaves that off). Path and query both survive:
   `https://www.…/faq?a=1` → `https://sideline-sidekick.com/faq?a=1`.

Deploying the rule shows a warning that `www` may not be proxied. It is stale if the DNS
record was just added — choose *Ignore and deploy rule anyway*, not *Create a new proxied
DNS record*, which would duplicate what is already there.

3. **Always Use HTTPS** (SSL/TLS → Edge Certificates), enabled 2026-08-12. The rule in
   step 2 matches `https` only, so before this `http://www.` returned 522 — the apex's own
   HTTP redirect comes from Pages rather than from a zone setting, which is why it never
   covered `www`. The scheme upgrade belongs at this layer, not duplicated into the
   redirect rule.

   The dashboard warns this setting can cause redirect loops when the origin also forces
   HTTPS redirects, and Pages does force them. It is safe here because the zone is on SSL
   mode **Full**: the edge fetches the origin over HTTPS, so Pages never issues its own
   redirect. **On Flexible this would loop forever** — the edge would fetch over HTTP,
   Pages would 301, and the browser would come round again. The proof it is not Flexible
   is that `https://sideline-sidekick.com` returned a clean 200 before the toggle was
   touched; under Flexible it would already have been looping.

All four combinations of scheme and hostname now serve the site — verified across `/`,
`/faq`, `/support` and `/privacy`. `http://www.…/faq` takes two hops:
`https://www.…/faq`, then `https://sideline-sidekick.com/faq`.

## Keeping the FAQ honest

`faq.html` describes what the app actually does, and the app changes. Answers that were
once marked with a `CHECK` comment — pricing, the minimum iOS version, the spreadsheet
export — were all settled on 2026-08-12 against the app source. Two are pinned to facts
that can drift:

- **Minimum iOS version** says 17, from `IPHONEOS_DEPLOYMENT_TARGET` in the app project.
- **The data export answer** describes five CSVs (play-by-play, players, formations and
  plays, drives, scoring), a per-game export and a season export. That comes from
  `Engine/SpreadsheetExport.swift`. It was wrong until 2026-08-12 — it claimed text and
  PDF only, which would have told a coach there was no spreadsheet export at all.

This site is the one privacy surface not in the app repo, so a code change never prompts
you to update it. `BACKLOG.md` in the app repo makes the same point about the privacy
policy.

## Two apps, two policies

`/headset-privacy` was added 2026-08-21 for **Sideline Headset**, which is a second App
Store app rather than a feature of the tracker. Keep them apart. The two collect
materially different things — the tracker stores a roster of named minors and sends
Crashlytics reports; Headset stores no student information, has no crash reporting, and
adds a microphone, live voice and local-network access the tracker has never had — and
Apple expects a policy that describes the app under review.

`headset-privacy.html` has to stay in step with three things outside this repo, all in
the Sideline Headset project on the Desktop: `Headset/PrivacyInfo.xcprivacy`, the App
Store Connect privacy answers, and `SUBMISSION.md` §3. Its own HTML comment says so, and
says which of its claims are load-bearing.
