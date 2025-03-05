---
date: "2024-04-10"
---

# Home Directory at SFTP Server

> Updated 2024-03-04

In this blog post, I discuss how I've begun to centralize the data I use on a daily basis. My intention at the long run is to gather all my data in one place, and in such a form that it is directly accessible from any device.

## Introduction

The idea originated when I realized I had left a file in my PC's home directory that I wanted to access on the go, but my computer was turned off. I was already used to being able to access most of my data because of my habit of storing files on an SFTP server, which I can access from any device. I had a setup where the SFTP folder automatically mounts on my PC at the '/mnt/sftp' mount point, and I can access it on my phone using a third-party file manager like Cx File Explorer. This setup already significantly improved data availability and reduced the need to transfer files between devices.

In my newly envisioned scenario, regardless of the device being used, the home directory and files would remain identical in real-time, eliminating the need for any syncing mechanisms. To achieve this, I created a simple NixOS module for mounting remote directories over SSH. This module should be integrated into the user's modular configuration. Consequently, the SFTP mount of the home directory becomes user-centric rather than tied to any specific host, facilitating automatic addition to any machine utilized by the user.

## Setup

To achieve this, of course, we first need to enable SFTP on the server. I prefer to create a new user, assign the SFTP directory I would like to share as its home, and chroot the user there for security reasons:

```nix
# Create user and group
users.users."sftp" = {
  createHome = true;
  isSystemUser = true;
  useDefaultShell = false;
  group = "sftp";
  extraGroups = ["sshd"];
  home = "/mnt/sftp";
  openssh.authorizedKeys.keys = [ /* your public key */ ];
};
users.groups."sftp" = { };

# Enable SFTP and chroot the user to its home directory
services.openssh = {
  enable = true;
  allowSFTP = true;
  extraConfig = ''
    Match User sftp
      AllowTcpForwarding no
      ChrootDirectory %h
      ForceCommand internal-sftp
      PermitTunnel no
      X11Forwarding no
    Match all
  '';
};
```

Here is an example directory tree of the `/mnt/sftp` on the remote machine, which we want to use to centralize our daily data:
```
/mnt/sftp
├── home
│ ├── Documents
│ ├── Pictures
│ └── Workspace
└── media
```

Now, we can configure [the module](https://github.com/tupakkatapa/nix-config/blob/02fcd426d1d0f3a5f8740afb7d1e189f8dc0058a/nixosModules/sftp-client.nix) as follows:
```nix
services.sftpMount = {
  enable = true;

  # Use this private SSH key for auth
  defaults.IdentityFile = "/home/user/.ssh/id_ed25519";

  # Mount the SFTP root from the remote server
  mounts = [{
    what = "user@192.168.1.100:/";
    where = "/mnt/remote-sftp";
  }];

  # Link specific remote folders to local directories
  binds = [
    {
      what = "/mnt/remote-sftp/home/Downloads";
      where = "/home/user/Pictures";
    }
    {
      what = "/mnt/remote-sftp/home/Pictures";
      where = "/home/user/Pictures";
    }
    {
      what = "/mnt/remote-sftp/home/Workspace";
      where = "/home/user/Workspace";
    }
  ];
};
```

## Conclusion

There we go, now when our system boots up, it mounts the remote directories under our home directory. Nothing fancy, just works, and this simple approach ensures that my daily data is centralized and readily accessible, significantly enhancing my workflow and efficiency across all my devices.

