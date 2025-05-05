---
date: "2025-05-04"
---

# My First Upstream Kernel Patch

Last week, I submitted my first patch to the Linux kernel, and it has already been queued in the **for-leds-next** branch. It’s satisfying to see my name appear in the commit history of software I work with every day — software that runs on an absurd number of devices. That said, I’m still a bit concerned and wondering how a syntax error like this slipped through the usual layers of review and tooling.

**Commit**: [leds: pca995x: Fix typo in pca995x_of_match's of_device_id entry](https://git.kernel.org/pub/scm/linux/kernel/git/lee/leds.git/commit/?h=for-leds-next)

---

I tried to compile the Linux Kernel Driver Database (LKDDb) and hit a parsing error:

```
error: builder for '/nix/store/a7r0c0ypz005r11y4cw8inz2ypvj32sd-lkddb-trunk.drv' failed with exit code 1
       last 20 log lines:
       > Running phase: unpackPhase
       > unpacking source archive /nix/store/ac9pm8xb0v18z0wn6fhjx9p67rl0s21w-source
       > source root is source
       > Running phase: buildPhase
       > KERNELVERSION is not set
       > with special includes.  Check them from time to time.
       > Traceback (most recent call last):
       >   File "/build/source/./build-lkddb.py", line 77, in <module>
       >     make(args, kerneldir, dirs)
       >   File "/build/source/./build-lkddb.py", line 25, in make
       >     tree.scan_sources()
       >   File "/build/source/lkddb/__init__.py", line 151, in scan_sources
       >     b.scan()
       >   File "/build/source/lkddb/linux/browse_sources.py", line 126, in scan
       >     s.in_scan(src, filename)
       >   File "/build/source/lkddb/linux/browse_sources.py", line 173, in in_scan
       >     parse_struct(scanner, scanner.struct_fields, line, dep, filename)
       >   File "/build/source/lkddb/linux/browse_sources.py", line 197, in parse_struct
       >     raise lkddb.ParserError("in parse_line(): %s, %s, %s" % (filename, line, param))
       > lkddb.ParserError: in parse_line(): drivers/leds/leds-pca995x.c, [' .compatible = "nxp,pca9955b"', ' . data = &pca9955b_chipdef '], . data = &pca9955b_chipdef
       For full logs, run:
         nix log /nix/store/a7r0c0ypz005r11y4cw8inz2ypvj32sd-lkddb-trunk.drv
```

The kernel turned out to have a simple typo that prevented the database from compiling.

## Sending a patch

Contributing to the Linux kernel isn’t as daunting as it seems — once you understand the workflow. I referred to [the official guide](https://www.kernel.org/doc/html/latest/process/submitting-patches.html) for contributing to the kernel throughout the process of figuring this out. Here’s how I sent my patch upstream, step by step.

1. **Clone an up‑to‑date tree**

   ```bash
   git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
   cd linux
   ```

2. **Create a branch**

   ```bash
   git checkout -b leds-spacing-fix
   ```

3. **Make the changes**

3. **Create a commit**

   ```bash
   git commit -s -m 'leds: pca995x: fix typo

   Remove the stray space between the "." and the "data" field name in
   the PCA995x device‑tree match table.

   Signed-off-by: Jesse Karjalainen <jesse@ponkila.com>'
   ```

   The `-s` flag appends a *Developer Certificate of Origin* line to certify I wrote the patch. Ideally, you should also run style-check and test your changes. I skipped those because this one‑line fix is safe.

4. **Generate a mail‑ready patch**

   ```bash
   git format-patch -1 --base=auto
   ```

   This produces **0001-leds-pca995x-fix-spacing-typo.patch**.

5. **Find the maintainers**

   ```bash
   perl scripts/get_maintainer.pl 0001-*.patch
   ```

   Which returned:
   ```
   Lee Jones <lee@kernel.org> (maintainer:LED SUBSYSTEM)
   Pavel Machek <pavel@kernel.org> (maintainer:LED SUBSYSTEM)
   linux-leds@vger.kernel.org (open list:LED SUBSYSTEM)
   linux-kernel@vger.kernel.org (open list)
   ```

6. **Configure email**

   I initially struggled with Outlook — its mandatory OAuth authentication wouldn’t cooperate with `git send-email` — so I switched to my company account hosted on Hetzner instead, which worked like a charm.

   Here is the NixOS Home Manager setup I ended up with:

   ```nix
   accounts.email.accounts."ponkila" = {
     address = "jesse@ponkila.com";
     userName = "jesse@ponkila.com";
     realName = "Jesse Karjalainen";
     primary = true;
     imap = {
       host = "mail.your-server.de";
       port = 143;
       tls  = {
         enable = true;
         useStartTls = true;
       };
     };
     smtp = {
       host = "mail.your-server.de";
       port = 587;
       tls  = {
         enable = true;
         useStartTls = true;
       };
     };
     msmtp.enable = true;
   };
   programs.msmtp.enable = true;

   programs.git = {
     userName  = "Jesse Karjalainen";
     userEmail = "jesse@ponkila.com";
     extraConfig.sendemail = {
       smtpserver = "${pkgs.msmtp}/bin/msmtp";
     };
   };
   ```

   The guide at [https://git-send-email.io/](https://git-send-email.io/) was invaluable for testing the setup.

7. **Send the patch**

   ```bash
   git send-email \
     --to "linux-leds@vger.kernel.org" \
     --cc "Lee Jones <lee@kernel.org>" \
     --cc "Pavel Machek <pavel@kernel.org>" \
     --cc "linux-kernel@vger.kernel.org" \
     0001-leds-pca995x-fix-spacing-typo.patch
   ```

---

Submitting my first kernel patch was a rewarding experience. It was a minor fix, but contributing to such a large and important project felt meaningful. And best of all — LKDDb builds cleanly now.
