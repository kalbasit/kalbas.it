+++
tags = ["nixos"]
date = "2019-03-24T11:00:00-08:00"
description = "In this article, I go over why I use NixOS"
title = "Why I use NixOS"
highlight = true
css = []
scripts = []
+++

This post highlights my reasoning behind switching to NixOS. 

<!--more-->

_This was originally posted as a [Reddit comment][reddit-comment]._

## Linux/Unix History

Please head over to read all about my [Linux/Unix history][linux-unix-history].
In a Gist: I have about 20 years experience in using and managing Linux and
Unix machines ranging from various Linux distributions, as well as *BSD and by
extension Darwin (a.k.a Mac).

# Why did I switch to NixOS?

Last year -- 2018 -- I was still working as a co-founder of a small Ad-related
startup. I used to have crazy long days (averaging about 12-16 hours), and I
used to do about ten different things (in parallel). The reliability of my
machine to say the least is of utmost importance as my day (and thus my
productivity) depends on it.  One day early May of last year, I wanted to
install a new Vim plugin (can't remember the exact plugin) and I inadvertently
ran `:PlugUpdate` which updated all of my Vim plugins to the latest version and
this has broken my entire [Go][vim-go] setup. Not only I could no longer get
auto-completion as I was typing, but I was also greeted with a multi-line error
every time I open a Go file, attempted to edit something or save it. I had to
disable most of my plugins just to get by. By the end of that day, I was very
much late on my tasks and extremely frustrated, I decided to take the weekend
off and look for a solution!

My search term was very simple: [`Reproducible Vim
distribution`][reproducible-vim-search].  And that's how I found out about Nix.
It took me a good month of learn/test-on-vm/get-help/repeat until I was finally
ready to dual boot with Arch. Most of that time was spent trying to get the
work tools (Bazel with Proto/Go/Java/Javascript/TypeScript support) to work on
Nix.

My frustration with my setup was not caused necessarily by Arch, but by every
distribution that is not built with reproducibility in mind! I've attempted
different solutions over the years to solve this issue, and one that worked
half-well for me was to symlink the configuration of every application I use
from a Git (or SVN early-on). You can check out the pre-nix version of my
dotfiles [here](https://github.com/kalbasit/shabka/tree/pre-nix).

# What did NixOS provide me

- Reliability! Reliability! Reliability! Yes, it's that important to me! I'd
  rather have to [contrinube new packages][contribute-new-packages] than
  showing up at work with a broken system.
- Reproducibality: I use different computers for different purposes. When I fix
  something (say a bug in [my Vim workflow][vim-workflow]), I like to know that
  it has been fixed everywhere.
- Consistency: I can't describe how good it feels to set up unrelated software
  using the same syntax. Of course, it's doing all the hard work behind the
  scenes for you, and you might have to get your hands dirty to fix something,
  but in your day to day use it's just perfect.
- Recovery: If I lose or break my computer, I no longer have to worry about my
  config. I can just clone [shabka][shabka] on a new NixOS installation and run
  `./scripts/nixos-rebuild -h <host> switch` to get my entire system back.
- Reproducible development environment: We're about 40 engineers with mixed Mac
  and Linux workstations, yet we are all using the same reproducible
  environment. No more of "Where do I get libv8 again?"! Nix provide us a
  complete Bazel environment (for one repository) and a complete Rails env (for
  the other repository).

One minor improvement: For some reason, I could never get a cryptsetup/LUKS in
Arch to work in such a way that I have a Key partition used as the
password-file for decrypting other partitions. Because Nix is a lazy language
that allows you to determine the order of dependencies, I was [easily able to
achive this in
NixOS][hades-configuration].

Please note that I use NixOS a bit differently than other people. I have only
one repo, named [shabka][shabka], for setting up my
entire network (laptops, servers, VPN and soon router). It has support for
NixOS as well as Mac. I currently have 7 hosts: 2 Mac laptops, 3 NixOS laptops,
a VPN server on AWS and a baremetal server hosting a Windows server as well as
some internal sites to my home. Although the repo is public, it's not really
meant for anyone to use it as-is; It's customized to my setup but I am working
on an opinated multi-language multi-operating-system distribution (at the
design phase still).

# Areas that need improvement

It's now time to discuss the cons/bad/ugly: Essentially what we must improve in
NixOS. I'm a member of the project, but by *we* I really mean the open source
community and not just the members.

1. Lack of consise and up to date documentation. This has been discussed at
   length by other commenters, and is a very valid point. I'm considering
   writing a book given I still have a fresh noob perspective, more on that
   later.
1. Steep learning curve to the Nix concept, the language and Nixpkgs. I
   recently released a new [infrastructure for packaging Go modules][build-go-module]
   after actively contributing to the project for the past 9 months and I still
   feel like a noob in many areas.
1. Difficulty attempting to use something that is not packaged in NixOS:
    1. At work, we have a repository using Ansible and I can't figure out how
       to make it work on NixOS. I spent about an hour on it before giving up.
       I have an Ubuntu VM to deal with it now.
    1. I use i3wm. When I was using Arch, I used to use
       [whatsapp-nativefier][whatsapp-notifier]
       from AUR and I can't figure out how to package it due to lack of
       documentation around packaging Electron applications. I could also be
       looking at the wrong place for documentation (back to point 1 here).
    1. It's difficult to run a pre-compiled binary. None of the dependencies
       are available at the location hardcoded in the binary (usually at
       /usr/lib). Using patchelf might work, but in my experience, it's easier
       to just create a package for it. You can see where Nix falls of short of
       other distros where you can just download a binary and run it.
1. Re-design NixOPS. Currently, It assume all servers are [pets instead of
   cattle][pets-vs-cattle].
   It also hardcode all the paths in a sqlite database where the state of the
   servers (and the SSH keys) are stored, so most SRE end up creating a deploy
   server (only one). And finally, it should be able to work alongside and not
   replacing Terraform IMO, this solves the pet/kettle as well as the deploy
   concept.
1. Inconsistent command line tools: nix-shell, nix-build, nix-env and
   nix-instantiate all expect a slightly different arguments and it's
   frustrating to have to remember them all. Nix 2.0 does include a `nix`
   command line to help standarize the flags, but it's still early-on and does
   not yet fully replace the old tools.

# Conclusion

Nix is an amazing concept developed by a small community of amazing people.
IMO, it has long way to go, and does need support from a larger company to be a
successful project. I can see this a reality one day.

If it makes sense for you to use it, I say by all means. It's a win-win for you
as a user and for us as maintainers if the community grew larger by one new
member :)


[reddit-comment]: https://www.reddit.com/r/archlinux/comments/b2jkrp/anyone_tried_nixos_what_are_your_thoughts/eixbwu6
[build-go-module]: {{< ref "announcing-new-go-infra" >}}
[whatsapp-notifier]: https://aur.archlinux.org/packages/whatsapp-nativefier/
[pets-vs-cattle]: https://medium.com/@Joachim8675309/devops-concepts-pets-vs-cattle-2380b5aab313
[hades-configuration]: https://github.com/kalbasit/shabka/blob/4b93eac50623779bb71deed3e57cb3db6b85423c/hosts/hades/hardware-configuration.nix#L36-L41
[contribute-new-packages]: https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+sort%3Aupdated-desc+author%3Akalbasit+is%3Aclosed+label%3A%228.has%3A+package+%28new%29%22
[vim-workflow]: https://github.com/kalbasit/shabka/pull/178
[shabka]: https://github.com/kalbasit/shabka
[vim-go]: https://github.com/fatih/vim-go
[linux-unix-history]: {{< ref "linux-unix-history" >}}
[reproducible-vim-search]: https://www.google.com/search?q=Reproducible+Vim+distribution
