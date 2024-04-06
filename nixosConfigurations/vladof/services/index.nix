{ pkgs
, lib
, domain
, servicesConfig
,
}:
let
  # HTML file content with inline CSS
  html = pkgs.writeText "index.html" ''
    <html>
    <head>
      <title>Service Index</title>
      <style>
          body, html {
              font-family: 'IBM Plex Mono', sans-serif;
              background-color: #121212;
              color: #fff;
              margin: 0;
              padding: 0;
              height: 100vh;
              overflow: auto;
          }
          #container {
              position: absolute;
              top: 50px;
              left: 0;
              right: 0;
              width: 900px;
              margin: auto;
              background-color: #1f1f1f;
              font-size: 16px;
              line-height: 1.6;
              color: #e8e8e8;
              padding-top: 30px;
              padding-bottom: 40px;
              padding-left: 75px;
              padding-right: 75px;
              border-radius: 10px;
              border: 1px solid #333;
              overflow-y: auto;
          }
          h1 {
              color: #eee;
              font-size: 24px;
              margin-top: 24px;
              margin-bottom: 16px;
              font-weight: 700;
              line-height: 1.25;
          }
          ul {
              list-style-type: none;
              padding: 0;
          }
          li {
              padding: 10px 0;
              border-bottom: 1px solid #2A2A2A;
          }
          li:last-child {
              border-bottom: none;
          }
          a {
              text-decoration: none;
              color: #1e90ff;
              transition: color 0.3s ease;
          }
          a:hover {
              text-decoration: underline;
              color: #63B3ED;
          }
      </style>
    </head>
    <body>
      <div id="container" class="markdown-body">
        <h1>Services on ${domain}</h1>
        <ul>
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: service: ''
        <li><a href="http://${service.addr}">${name}</a></li>
      '')
      servicesConfig)}
        </ul>
      </div>
    </body>
    </html>
  '';
in
pkgs.runCommand "indexPage" { } ''
  mkdir -p $out
  cp ${html} $out/index.html
''
