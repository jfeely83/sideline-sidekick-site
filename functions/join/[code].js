// /join/<CODE> — serve the invite page with a 200.
//
// Why a Function and not a rewrite: the "/join/* /join/index.html 200" rule in
// public/_redirects is thrown away by the Pages redirect parser (loop
// detection), so a shared link fell through to public/join/404.html — the right
// page, but with HTTP status 404. Browsers do not care. Link-preview fetchers
// do: iMessage will not build a preview card from a 404, so the text every
// coach sends showed a bare "sideline-sidekick.com" instead of the card
// (seen on a device, 2026-09-21).
//
// This answers /join/<anything> with the bytes of /join/ (public/join/index.html,
// which reads the code out of the path in the browser) and status 200. Real
// files under /join/ never reach here — see public/_routes.json. If this
// Function is ever removed or fails to deploy, public/join/404.html is still
// the fallback, exactly as before.
export async function onRequest(context) {
  const url = new URL(context.request.url);
  url.pathname = "/join/";
  url.search = "";
  const asset = await context.env.ASSETS.fetch(new Request(url.toString(), { method: "GET" }));
  const headers = new Headers(asset.headers);
  headers.set("Cache-Control", "public, max-age=300");
  return new Response(context.request.method === "HEAD" ? null : asset.body, {
    status: asset.ok ? 200 : asset.status,
    headers,
  });
}
