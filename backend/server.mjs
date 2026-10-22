import http from "node:http";

const PORT = Number(process.env.PORT || 8787);
const IDEAL_POSTCODES_API_KEY = process.env.IDEAL_POSTCODES_API_KEY;

function sendJson(response, status, payload) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "access-control-allow-origin": process.env.ALLOWED_ORIGIN || "*",
    "access-control-allow-methods": "GET, OPTIONS",
    "access-control-allow-headers": "Accept, Content-Type",
  });
  response.end(JSON.stringify(payload));
}

function asString(value) {
  return value === undefined || value === null ? "" : String(value).trim();
}

function asNumber(value) {
  if (value === undefined || value === null || value === "") return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function formatAddress(record) {
  const lines = [
    record.organisation_name,
    record.line_1,
    record.line_2,
    record.line_3,
    record.post_town,
    record.postcode,
    record.country,
  ].map(asString).filter(Boolean);
  return [...new Set(lines)].join(", ");
}

const server = http.createServer(async (request, response) => {
  if (request.method === "OPTIONS") {
    response.writeHead(204, {
      "access-control-allow-origin": process.env.ALLOWED_ORIGIN || "*",
      "access-control-allow-methods": "GET, OPTIONS",
      "access-control-allow-headers": "Accept, Content-Type",
    });
    response.end();
    return;
  }

  const url = new URL(request.url || "/", `http://${request.headers.host || "localhost"}`);

  if (request.method === "GET" && url.pathname === "/health") {
    sendJson(response, 200, { status: "ok", providerConfigured: Boolean(IDEAL_POSTCODES_API_KEY) });
    return;
  }

  if (request.method !== "GET" || url.pathname !== "/v1/addresses") {
    sendJson(response, 404, { error: "Not found." });
    return;
  }

  const postcode = (url.searchParams.get("postcode") || "").trim().toUpperCase().replace(/\s+/g, " ");
  const postcodePattern = /^(GIR 0AA|[A-Z]{1,2}\d[A-Z\d]? \d[A-Z]{2})$/;
  if (!postcodePattern.test(postcode)) {
    sendJson(response, 400, { error: "Enter a valid UK postcode." });
    return;
  }
  if (!IDEAL_POSTCODES_API_KEY) {
    sendJson(response, 503, { error: "Address provider is not configured on the server." });
    return;
  }

  try {
    const providerUrl = new URL(`https://api.ideal-postcodes.co.uk/v1/postcodes/${encodeURIComponent(postcode)}`);
    providerUrl.searchParams.set("api_key", IDEAL_POSTCODES_API_KEY);
    const providerResponse = await fetch(providerUrl, {
      headers: { accept: "application/json" },
      signal: AbortSignal.timeout(12000),
    });
    const providerBody = await providerResponse.json().catch(() => ({}));

    if (providerResponse.status === 404) {
      sendJson(response, 404, {
        error: "No addresses were found for that postcode.",
        suggestions: Array.isArray(providerBody.suggestions) ? providerBody.suggestions : [],
      });
      return;
    }
    if (!providerResponse.ok) {
      // Do not forward provider error details or the secret API key to the app.
      sendJson(response, 502, { error: "The address provider could not complete the lookup." });
      return;
    }

    const result = Array.isArray(providerBody.result) ? providerBody.result : [];
    const addresses = result.map((record, index) => {
      const latitude = asNumber(record.latitude);
      const longitude = asNumber(record.longitude);
      const uprn = asString(record.uprn) || null;
      const udprn = asString(record.udprn) || null;
      const country = asString(record.country);
      const isNorthernIreland = /northern ireland/i.test(country);
      const coordinateAccuracy = latitude === null || longitude === null
        ? "unavailable"
        : (uprn && !isNorthernIreland ? "rooftop" : "postcode-centroid");

      return {
        id: asString(record.id) || (udprn ? `udprn-${udprn}` : `address-${index}`),
        formattedAddress: formatAddress(record),
        postcode: asString(record.postcode) || postcode,
        latitude,
        longitude,
        uprn,
        udprn,
        coordinateAccuracy,
      };
    }).filter((address) => address.formattedAddress.length > 0);

    sendJson(response, 200, { postcode, addresses });
  } catch {
    sendJson(response, 502, { error: "Address lookup is temporarily unavailable." });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`RoutePilot address service listening on port ${PORT}`);
});
