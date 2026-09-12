{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      # zyouz flake uses pkgs.zig.hook (Zig 0.16) but source targets 0.15.x.
      # build.zig.zon uses enum syntax (0.15+) and std.heap.GeneralPurposeAllocator
      # was removed in 0.16. zig_0_15 has both and works.
      packages.zyouz = pkgs.stdenv.mkDerivation {
        pname = "zyouz";
        version = "0.3.0";

        src = inputs.zyouz;
        nativeBuildInputs = singleton pkgs.zig_0_15.hook;
        dontUseZigCheck = true;

        meta.mainProgram = "zyouz";
      };
    };
}
