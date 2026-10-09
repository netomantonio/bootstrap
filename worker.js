// Cloudflare Worker: serve o install.sh publico do GitHub em um endereco curto (ex.: boot.exemplo.dev).
// Nao guarda nada e nao tem segredo; so repassa o arquivo do repo publico.
// Deploy (a verificar na doc do wrangler): wrangler deploy; depois ligar o dominio customizado ao Worker.
const RAW = "https://raw.githubusercontent.com/netomantonio/bootstrap/main/install.sh";

export default {
  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === "/" || pathname === "/i") {
      const upstream = await fetch(RAW, { cf: { cacheTtl: 0 } });
      if (!upstream.ok) return new Response("upstream error", { status: 502 });
      return new Response(upstream.body, {
        headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" },
      });
    }
    return new Response("not found", { status: 404 });
  },
};
