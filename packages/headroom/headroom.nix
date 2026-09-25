_: {
  perSystem =
    { pkgs, ... }:
    let
      py = pkgs.python313.pkgs;

      wheel =
        {
          x86_64-linux = {
            url = "https://files.pythonhosted.org/packages/72/b8/16878cf4fe6fc390a0d22025b671468619db690ff14c1b103ace4b5e35f9/headroom_ai-0.37.0-cp310-abi3-manylinux_2_28_x86_64.whl";
            hash = "sha256-Lvxc32gaEMX8eionGkcRecQJB0U3BF9oKxDk1ySXb0Y=";
          };
          aarch64-linux = {
            url = "https://files.pythonhosted.org/packages/c6/2e/8d1c60683c74ae2871270789e0af1acc93727a51189799e74529679d795c/headroom_ai-0.37.0-cp310-abi3-manylinux_2_28_aarch64.whl";
            hash = "sha256-vDDTGmuTNhVdYrvdmfPC9sWh7TiCqHMOoM2O3kxA+hk=";
          };
          aarch64-darwin = {
            url = "https://files.pythonhosted.org/packages/47/21/8a87b66e83498da89404cdba4ced6397e84331047df9e11a9ea6f3510b29/headroom_ai-0.37.0-cp310-abi3-macosx_11_0_arm64.whl";
            hash = "sha256-tDkvaKjQLXTGLBc0z1vzJ1EdzHJnjwFmn0TwYSlE1Zw=";
          };
          x86_64-darwin = {
            url = "https://files.pythonhosted.org/packages/56/cc/385712352911b7a482514902745cba802e03947850689a784b2d40764e06/headroom_ai-0.37.0-cp310-abi3-macosx_10_12_x86_64.whl";
            hash = "sha256-2J/VhY5wGtpT0BhJ9zA52JH62E2es3D5UtVlgZYtnPg=";
          };
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "headroom: unsupported system ${pkgs.stdenv.hostPlatform.system}");
    in
    {
      packages.headroom = py.buildPythonPackage {
        pname = "headroom-ai";
        version = "0.37.0";
        format = "wheel";
        src = pkgs.fetchurl { inherit (wheel) hash url; };

        # Minimal trial set: core plus proxy extra, which is exactly what
        # `headroom proxy` and `headroom wrap *` demand at runtime.
        # Torch-bearing extras (ml, memory, voice, evals) stay out.
        propagatedBuildInputs = [
          py.tiktoken
          py.pydantic
          py.litellm
          py.click
          py.rich
          py.opentelemetry-api
          py.ast-grep-cli
          py.pyyaml
          py.tomlkit
          py.fastapi
          py.uvicorn
          py.httpx
          py.openai
          py.mcp
          py.magika
          py.zstandard
          py.websockets
          py.onnxruntime
          py.pillow
          py.transformers
          py.typing-extensions
          py.watchdog
          py.sqlite-vec
          py.orjson
          py.h2
        ];

        # Why: compaction runs on every request. 1 MiB is below the
        # steady-state size of the 30-day savings ledger, so the full JSONL
        # file is re-read, parsed and rewritten under a lock per request.
        # `format = "wheel"` ships no unpacked tree, so unpack the fetched
        # wheel from dist/, patch the constant, and repack it. The body runs
        # in a subshell: a stray `cd` would leak into every later phase.
        postPatch = ''
          (
            shopt -s nullglob
            wheelroot="$TMPDIR/headroom-wheelroot"
            mkdir -p "$wheelroot"
            for whl in dist/*.whl; do
              ${pkgs.python313.interpreter} -m zipfile -e "$whl" "$wheelroot"
              substituteInPlace \
                "$wheelroot/headroom/savings_ledger.py" \
                --replace-fail '_COMPACT_SIZE_BYTES = 1 * 1024 * 1024' \
                '_COMPACT_SIZE_BYTES = 64 * 1024 * 1024'
              # `/stats` recomputes throughput with
              # `parse_log_files(last_n_hours=1.0)`, which re-reads and
              # regex-parses every rotated proxy log inside the window. At
              # the upstream 10s TTL a 10 MB rotation is re-parsed every
              # 10s, which is a 0.14s / 16%-of-a-core spike each time.
              # 300s cuts that by 30x; throughput stats go up to 5 min stale.
              substituteInPlace \
                "$wheelroot/headroom/proxy/server.py" \
                --replace-fail 'THROUGHPUT_CACHE_TTL_SECONDS = 10.0' \
                'THROUGHPUT_CACHE_TTL_SECONDS = 300.0'
              patched="$PWD/dist/$(basename "$whl")"
              rm "$whl"
              ( cd "$wheelroot" && ${pkgs.python313.interpreter} -m zipfile -c "$patched" * )
              break
            done
          )
        '';

        doCheck = false;
        doInstallCheck = false;
        meta = {
          description = "Context compression layer for AI agents";
          homepage = "https://github.com/headroomlabs-ai/headroom";
          license = pkgs.lib.licenses.asl20;
          mainProgram = "headroom";
        };
      };
    };
}
