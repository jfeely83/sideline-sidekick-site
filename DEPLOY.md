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
`wrangler deploy` — that is the Workers command, and it publishes to a Worker that
nothing points at.

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

## Still to fill in

1. **The call-to-action buttons.** Both primary CTAs on the home page are
   `mailto:support@sideline-sidekick.com` links. If the app should send people to
   TestFlight or the App Store, that URL needs to replace the `mailto:` in the two
   `.btn--primary` anchors in `index.html`.

2. **Screenshots.** `public/screenshots/` is empty. Add `log.png`, `stats.png`,
   `report.png` and `roster.png`, then in `index.html` delete the four
   `frame--empty` placeholder divs and uncomment the `<img>` tag above each.
   Use the demo team, not a real roster.

3. **Two unverified answers in the FAQ**, both marked with a `CHECK` comment in
   `faq.html`: what the app costs after the beta, and whether there is any data
   export beyond text and PDF. These are live on the public site as written.
