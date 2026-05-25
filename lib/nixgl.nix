# lib/nixgl.nix
#
# mkNixGLWrapper: given pkgs, lib, a nixGL package, and an isNixOS flag,
# returns a function { pkg, bins ? null } -> derivation.
#
# - If isNixOS: returns pkg unchanged (no-op).
# - Otherwise: returns a symlinkJoin of pkg where each named binary (or, if
#   bins is null, pkg.passthru.guiBins, or, if that's also missing, every
#   executable in $out/bin) is replaced with a makeWrapper script that
#   execs nixGL with the original binary as its argument.
{ pkgs, lib, nixGL, isNixOS }:

{ pkg, bins ? null }:

let
  binsToWrap =
    if bins != null then bins
    else if pkg ? guiBins then pkg.guiBins
    else null;  # null means "wrap everything in $out/bin"
in
if isNixOS then pkg
else pkgs.symlinkJoin {
  name = "${pkg.name}-nixgl";
  paths = [ pkg ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrap_one() {
      local bin="$1"
      [ -e "$out/bin/$bin" ] || return 0
      local target
      target=$(readlink -f "$out/bin/$bin")
      rm "$out/bin/$bin"
      makeWrapper "${nixGL}/bin/nixGL" "$out/bin/$bin" \
        --add-flags "$target"
    }
  '' + (
    if binsToWrap == null then ''
      mapfile -t _bins < <(find "$out/bin" -maxdepth 1 -type f -executable -printf '%f\n')
      for b in "''${_bins[@]}"; do wrap_one "$b"; done
    ''
    else lib.concatMapStringsSep "\n" (b: ''wrap_one "${b}"'') binsToWrap
  );
}
