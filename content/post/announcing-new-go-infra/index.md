+++
tags = [ "nix", "nixpkgs", "golang" ]
date = "2019-03-17T19:53:00-08:00"
description = "buildGoModule is a new infrastructure in Nixpkgs that relies on Go's module reproducibility to make it simpler to package Go modules"
title = "Announcing the new Golang infrastructure: buildGoModule"
highlight = true
css = []
scripts = []
+++

I recently introduced a new function in Nixpkgs named `buildGoModule`. The new
function allows you to package Go application (or modules) with ease, provided
the modules have added support for [Go
modules](https://github.com/golang/go/wiki/Modules) upstream.

<!--more-->

The build happens in two phases:

1. An intermediate fetcher derivation. This derivation will be used to fetch
   all of the dependencies of the Go module. The checksum of the dependencies
   will be compared against the `modSha256` attribute that is passed in.
2. A final derivation will use the output of the intermediate derivation to
   build the binaries and produce the final output.

The following derivation demonstrate how to package [pet](https://github.com/knqyf263/pet):

{{< code file="/content/post/announcing-new-go-infra/pet.nix" language="nix" >}}

Notice that we did not have to specify `deps` nor `goPackagePath` for this to
work, as with the legacy `buildGoPackage`.

## How does it work

The first phase is referred to as `go-modules` and the second is referred to as
`package`. The former prepares the dependencies white the latter uses the
dependencies in order to compile the final output.

### go-modules

The go-modules derivation starts by setting up the environment necessary to
allow Go to have network access (even from within the sandbox). It does so by
setting the attributes `outputHashAlgo` and `outputHash` as is the case with
any other fetcher. At the end of the derivation, the hash computed according to
`outputHashAlgo` will be expected to match the hash found in `outputHash` with
is coming from the `modSha256` attribute.

The derivation would also set up `GOPATH` and the `GOCACHE` in a temporary
writable location.

During the build phase, the `src` will be unpacked and patched with `patches`,
if any. The derivation then executes the command `go mod download` from within
the root directory of the module. This command will download all of the
dependencies recursively and store them in `$GOPATH/pkg/mod`.

During the install phase, it takes the entire `$GOPATH/pkg/mod/cache/download`
as the output `$out`. The hash verification will now be performed before
returning `$out` to the caller.

One might wonder why does the derivation only use
`$GOPATH/pkg/mod/cache/download` instead of the entire `$GOPATH/pkg/mod`
directory. This is because the directory `$GOPATH/pkg/mod/cache/vcs` is impure
as it reflects the repositories upstream as they were seen at the time of
the cloning. Checkout the thread over on
[golang-nuts](https://groups.google.com/forum/#!topic/golang-nuts/i0_yZ7CellI)
for more information.

### package

This derivation will start similarly to the above one, by setting up the
environment in order to have Go find all the necessary modules **without
network access**. The lack of network access is very important here, and it
allows us to build the module within an off-line sandbox. This step relies on
setting `GOPROXY` environment variable to the output of the `go-modules`
derivation we've built earlier. Go will use this information to locate the
repositories of all the dependencies and construct the entire
`$GOPATH/pkg/mod`.

{{< highlight shell >}}
export GOPROXY=file://${go-modules}
{{< /highlight >}}
