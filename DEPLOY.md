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
| `privacy.html` | `/privacy` | Privacy policy                               |
| `styles.css`   |            | One stylesheet for every page                |
| `logo.png`     |            | Header mark and favicon, 96px                |
| `_redirects`   |            | Sends unknown paths to the splash page       |

## Unknown paths

`public/_redirects` contains a single rule:

```
/* /index.html 200
```

Anything that does not match a real file serves the splash page with a **200**, which
is what the site has always done. Real assets still win, so `/faq` serves `faq.html`.

**Do not add `public/404.html`.** Pages serves a `404.html` found in the output
directory for every unmatched request, and that takes precedence over the rule above —
adding the file silently turns the splash fallback back into a 404. The old 404 page is
in git history if it is ever wanted.

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

**DMARC is still missing** — `_dmarc.sideline-sidekick.com` returns nothing. Add a TXT
record named `_dmarc` with the value:

```
v=DMARC1; p=none; rua=mailto:support@sideline-sidekick.com
```

`p=none` is monitoring only: nothing gets blocked, and the aggregate reports show who is
sending as the domain. Since nothing legitimately sends as it, `p=reject` is the correct
end state — move there once a month of reports comes back clean.

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
