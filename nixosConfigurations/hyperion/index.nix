{ pkgs, domain, ... }:
let
  indexPage = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html>
    <html>
    <head>
      <title>${domain}</title>
      <style>
        body, html {
          font-family: 'IBM Plex Mono', monospace;
          background-color: #121212;
          color: #fff;
          margin: 0;
          padding: 0;
          height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        #container {
          background-color: #1f1f1f;
          padding: 40px 60px;
          border-radius: 10px;
          border: 1px solid #333;
          text-align: center;
        }
        h1 {
          color: #eee;
          font-size: 24px;
          margin: 0 0 16px 0;
        }
        p {
          color: #888;
          margin: 0;
        }
      </style>
    </head>
    <body>
      <div id="container">
        <h1>${domain}</h1>
        <p>hyperion</p>
      </div>
    </body>
    </html>
  '';
in
{
  services.nginx.virtualHosts."${domain}" = {
    default = true;
    root = indexPage;
    listen = [
      { addr = "10.42.0.1"; port = 80; }
      { addr = "10.42.1.1"; port = 80; }
      { addr = "172.16.16.1"; port = 80; }
    ];
  };
}
