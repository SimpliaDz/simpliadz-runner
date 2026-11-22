import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer, request as requestToApi } from 'node:http';
import { extname, resolve, sep } from 'node:path';

const argumentsByName = new Map();
for (let index = 2; index < process.argv.length; index += 2) {
  argumentsByName.set(process.argv[index], process.argv[index + 1]);
}

const outputRoot = resolve(requiredArgument('--root'));
const apiTarget = new URL(requiredArgument('--api-target'));
const port = Number(requiredArgument('--port'));

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2',
};

function requiredArgument(name) {
  const value = argumentsByName.get(name);
  if (!value) {
    throw new Error(`Missing ${name}.`);
  }
  return value;
}

function localeAndPath(pathname) {
  const segments = pathname.split('/').filter(Boolean);
  const locale = ['fr', 'ar', 'en-US'].includes(segments[0]) ? segments.shift() : 'en-US';
  return { locale, relativePath: segments.join('/') };
}

function safeFilePath(locale, relativePath) {
  const localeRoot = resolve(outputRoot, locale);
  const candidate = resolve(localeRoot, relativePath || 'index.html');
  if (candidate !== localeRoot && !candidate.startsWith(`${localeRoot}${sep}`)) {
    return null;
  }
  return candidate;
}

function sendFile(response, filePath) {
  response.statusCode = 200;
  response.setHeader('Content-Type', mimeTypes[extname(filePath)] ?? 'application/octet-stream');
  response.setHeader('Cache-Control', 'no-cache');
  createReadStream(filePath).pipe(response);
}

function proxyApi(request, response, url) {
  const apiPath = `${url.pathname.replace(/^\/api(?=\/|$)/, '')}${url.search}` || '/';
  const proxiedRequest = requestToApi(
    {
      protocol: apiTarget.protocol,
      hostname: apiTarget.hostname,
      port: apiTarget.port,
      method: request.method,
      path: apiPath,
      headers: { ...request.headers, host: apiTarget.host },
    },
    (apiResponse) => {
      response.writeHead(apiResponse.statusCode ?? 502, apiResponse.headers);
      apiResponse.pipe(response);
    },
  );
  proxiedRequest.on('error', (error) => {
    response.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
    response.end(JSON.stringify({ message: `Local API proxy failed: ${error.message}` }));
  });
  request.pipe(proxiedRequest);
}

createServer((request, response) => {
  const url = new URL(request.url ?? '/', 'http://localhost');
  if (url.pathname === '/api' || url.pathname.startsWith('/api/')) {
    proxyApi(request, response, url);
    return;
  }

  const { locale, relativePath } = localeAndPath(decodeURIComponent(url.pathname));
  let filePath = safeFilePath(locale, relativePath);
  if (filePath && (!existsSync(filePath) || statSync(filePath).isDirectory())) {
    // Angular routes are client-side. Assets have extensions and should still return 404.
    filePath = extname(relativePath) ? null : safeFilePath(locale, 'index.html');
  }

  if (!filePath || !existsSync(filePath)) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Not found');
    return;
  }

  sendFile(response, filePath);
}).listen(port, '127.0.0.1', () => {
  console.log(`Serving localized web build at http://localhost:${port}`);
  console.log(`  English: http://localhost:${port}/`);
  console.log(`  Français: http://localhost:${port}/fr/`);
  console.log(`  العربية: http://localhost:${port}/ar/`);
  console.log(`  API proxy: ${apiTarget.href}`);
});
