{ pkgs, lib, beamPackages, overrides ? (x: y: { }) }:

let
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;

  defaultOverrides = (final: prev:

    let
      apps = {
        explorer = [
          {
            name = "rustlerPrecompiled";
            toolchain = {
              name = "nightly-2024-07-26";
              sha256 = "sha256-5icy5hSaQy6/fUim9L2vz2GeZNC3fX1N5T2MjnkTplc=";
            };
          }
        ];
        tokenizers = [
          {
            name = "rustlerPrecompiled";
          }
        ];
      };

      elixirConfig = pkgs.writeTextDir
        "config/config.exs"
        ''
          import Config

          config :explorer, Explorer.PolarsBackend.Native,
            skip_compilation?: true

          config :tokenizers, Tokenizers.Native,
            skip_compilation?: true
        '';

      buildNativeDir = src: "${src}/native/${with builtins; head (attrNames (readDir "${src}/native"))}";

      workarounds = {
        rustlerPrecompiled = { toolchain ? null, ... }: old:
          let
            extendedPkgs = pkgs.extend fenixOverlay;
            fenixOverlay = import
              "${fetchTarball {
                url = "https://github.com/nix-community/fenix/archive/43efa7a3a97f290441bd75b18defcd4f7b8df220.tar.gz";
                sha256 = "sha256:1b9v45cafixpbj6iqjw3wr0yfpcrh3p11am7v0cjpjq5n8bhs8v3";
              }}/overlay.nix";
            nativeDir = buildNativeDir old.src;
            fenix =
              if toolchain == null
              then extendedPkgs.fenix.stable
              else extendedPkgs.fenix.fromToolchainName toolchain;
            native = (extendedPkgs.makeRustPlatform {
              inherit (fenix) cargo rustc;
            }).buildRustPackage {
              pname = "${old.packageName}-native";
              version = old.version;
              src = nativeDir;
              cargoLock = {
                lockFile = "${nativeDir}/Cargo.lock";
              };
              nativeBuildInputs = [ extendedPkgs.cmake ] ++ extendedPkgs.lib.lists.optional extendedPkgs.stdenv.isDarwin extendedPkgs.darwin.IOKit;
              doCheck = false;
            };
          in
          {
            nativeBuildInputs = [ extendedPkgs.cargo ];

            appConfigPath = "${elixirConfig}/config";

            env.RUSTLER_PRECOMPILED_FORCE_BUILD_ALL = "true";
            env.RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH = "unused-but-required";

            preConfigure = ''
              mkdir -p priv/native
              for lib in ${native}/lib/*
              do
                ln -s "$lib" "priv/native/$(basename "$lib")"
              done
            '';
          };
      };

      applyOverrides = appName: drv:
        let
          allOverridesForApp = builtins.foldl'
            (acc: workaround: acc // (workarounds.${workaround.name} workaround) drv)
            { }
            apps.${appName};

        in
        if builtins.hasAttr appName apps
        then
          drv.override allOverridesForApp
        else
          drv;

    in
    builtins.mapAttrs
      applyOverrides
      prev);

  self = packages // (defaultOverrides self packages) // (overrides self packages);

  packages = with beamPackages; with self; {
    ash =
      let
        version = "3.4.28";
      in
      buildMix {
        inherit version;
        name = "ash";

        src = fetchHex {
          inherit version;
          pkg = "ash";
          sha256 = "7faafca1f6b70bf2e72dbabef0d667ee2108923df465878e94f03b2ea8c24fe8";
        };

        beamDeps = [ decimal ecto ets igniter jason owl picosat_elixir plug reactor spark splode stream_data telemetry ];
      };

    ash_admin =
      let
        version = "0.11.6";
      in
      buildMix {
        inherit version;
        name = "ash_admin";

        src = fetchHex {
          inherit version;
          pkg = "ash_admin";
          sha256 = "6419207e962ff9e048f8bf9500a5c33185262366f162402574ef9edcaeebe453";
        };

        beamDeps = [ ash ash_phoenix gettext jason phoenix phoenix_html phoenix_live_view phoenix_view ];
      };

    ash_phoenix =
      let
        version = "2.1.4";
      in
      buildMix {
        inherit version;
        name = "ash_phoenix";

        src = fetchHex {
          inherit version;
          pkg = "ash_phoenix";
          sha256 = "d44004070e07ec342e754144a3474c45b7d38f0d47de5cbbbfb6219b65eebdf1";
        };

        beamDeps = [ ash phoenix phoenix_html phoenix_live_view ];
      };

    ash_postgres =
      let
        version = "2.4.8";
      in
      buildMix {
        inherit version;
        name = "ash_postgres";

        src = fetchHex {
          inherit version;
          pkg = "ash_postgres";
          sha256 = "bfd013c838d62977d71156220a43a287cab0c4e3f315f692123a316bc52319a4";
        };

        beamDeps = [ ash ash_sql ecto ecto_sql igniter inflex jason owl postgrex ];
      };

    ash_sql =
      let
        version = "0.2.36";
      in
      buildMix {
        inherit version;
        name = "ash_sql";

        src = fetchHex {
          inherit version;
          pkg = "ash_sql";
          sha256 = "a95b5ebccfe5e74d7fc4e46b104abae4d1003b53cbc8418fcb5fa3c6e0c081a9";
        };

        beamDeps = [ ash ecto ecto_sql ];
      };

    bandit =
      let
        version = "1.5.7";
      in
      buildMix {
        inherit version;
        name = "bandit";

        src = fetchHex {
          inherit version;
          pkg = "bandit";
          sha256 = "f2dd92ae87d2cbea2fa9aa1652db157b6cba6c405cb44d4f6dd87abba41371cd";
        };

        beamDeps = [ hpax plug telemetry thousand_island websock ];
      };

    castore =
      let
        version = "1.0.9";
      in
      buildMix {
        inherit version;
        name = "castore";

        src = fetchHex {
          inherit version;
          pkg = "castore";
          sha256 = "5ea956504f1ba6f2b4eb707061d8e17870de2bee95fb59d512872c2ef06925e7";
        };
      };

    db_connection =
      let
        version = "2.7.0";
      in
      buildMix {
        inherit version;
        name = "db_connection";

        src = fetchHex {
          inherit version;
          pkg = "db_connection";
          sha256 = "dcf08f31b2701f857dfc787fbad78223d61a32204f217f15e881dd93e4bdd3ff";
        };

        beamDeps = [ telemetry ];
      };

    decimal =
      let
        version = "2.1.1";
      in
      buildMix {
        inherit version;
        name = "decimal";

        src = fetchHex {
          inherit version;
          pkg = "decimal";
          sha256 = "53cfe5f497ed0e7771ae1a475575603d77425099ba5faef9394932b35020ffcc";
        };
      };

    dns_cluster =
      let
        version = "0.1.3";
      in
      buildMix {
        inherit version;
        name = "dns_cluster";

        src = fetchHex {
          inherit version;
          pkg = "dns_cluster";
          sha256 = "46cb7c4a1b3e52c7ad4cbe33ca5079fbde4840dedeafca2baf77996c2da1bc33";
        };
      };

    ecto =
      let
        version = "3.12.4";
      in
      buildMix {
        inherit version;
        name = "ecto";

        src = fetchHex {
          inherit version;
          pkg = "ecto";
          sha256 = "ef04e4101688a67d061e1b10d7bc1fbf00d1d13c17eef08b71d070ff9188f747";
        };

        beamDeps = [ decimal jason telemetry ];
      };

    ecto_sql =
      let
        version = "3.12.1";
      in
      buildMix {
        inherit version;
        name = "ecto_sql";

        src = fetchHex {
          inherit version;
          pkg = "ecto_sql";
          sha256 = "aff5b958a899762c5f09028c847569f7dfb9cc9d63bdb8133bff8a5546de6bf5";
        };

        beamDeps = [ db_connection ecto postgrex telemetry ];
      };

    elixir_make =
      let
        version = "0.8.4";
      in
      buildMix {
        inherit version;
        name = "elixir_make";

        src = fetchHex {
          inherit version;
          pkg = "elixir_make";
          sha256 = "6e7f1d619b5f61dfabd0a20aa268e575572b542ac31723293a4c1a567d5ef040";
        };

        beamDeps = [ castore ];
      };

    esbuild =
      let
        version = "0.8.1";
      in
      buildMix {
        inherit version;
        name = "esbuild";

        src = fetchHex {
          inherit version;
          pkg = "esbuild";
          sha256 = "25fc876a67c13cb0a776e7b5d7974851556baeda2085296c14ab48555ea7560f";
        };

        beamDeps = [ castore jason ];
      };

    ets =
      let
        version = "0.9.0";
      in
      buildMix {
        inherit version;
        name = "ets";

        src = fetchHex {
          inherit version;
          pkg = "ets";
          sha256 = "2861fdfb04bcaeff370f1a5904eec864f0a56dcfebe5921ea9aadf2a481c822b";
        };
      };

    expo =
      let
        version = "1.1.0";
      in
      buildMix {
        inherit version;
        name = "expo";

        src = fetchHex {
          inherit version;
          pkg = "expo";
          sha256 = "fbadf93f4700fb44c331362177bdca9eeb8097e8b0ef525c9cc501cb9917c960";
        };
      };

    finch =
      let
        version = "0.19.0";
      in
      buildMix {
        inherit version;
        name = "finch";

        src = fetchHex {
          inherit version;
          pkg = "finch";
          sha256 = "fc5324ce209125d1e2fa0fcd2634601c52a787aff1cd33ee833664a5af4ea2b6";
        };

        beamDeps = [ mime mint nimble_options nimble_pool telemetry ];
      };

    floki =
      let
        version = "0.36.2";
      in
      buildMix {
        inherit version;
        name = "floki";

        src = fetchHex {
          inherit version;
          pkg = "floki";
          sha256 = "a8766c0bc92f074e5cb36c4f9961982eda84c5d2b8e979ca67f5c268ec8ed580";
        };
      };

    gettext =
      let
        version = "0.26.1";
      in
      buildMix {
        inherit version;
        name = "gettext";

        src = fetchHex {
          inherit version;
          pkg = "gettext";
          sha256 = "01ce56f188b9dc28780a52783d6529ad2bc7124f9744e571e1ee4ea88bf08734";
        };

        beamDeps = [ expo ];
      };

    glob_ex =
      let
        version = "0.1.9";
      in
      buildMix {
        inherit version;
        name = "glob_ex";

        src = fetchHex {
          inherit version;
          pkg = "glob_ex";
          sha256 = "be72e584ad1d8776a4d134d4b6da1bac8b80b515cdadf0120e0920b9978d7f01";
        };
      };

    hpax =
      let
        version = "1.0.0";
      in
      buildMix {
        inherit version;
        name = "hpax";

        src = fetchHex {
          inherit version;
          pkg = "hpax";
          sha256 = "7f1314731d711e2ca5fdc7fd361296593fc2542570b3105595bb0bc6d0fad601";
        };
      };

    igniter =
      let
        version = "0.3.57";
      in
      buildMix {
        inherit version;
        name = "igniter";

        src = fetchHex {
          inherit version;
          pkg = "igniter";
          sha256 = "086a9430bc55b7ace4eb67a1c71649a25f9cf64c634df405aae2987b485b3fb4";
        };

        beamDeps = [ glob_ex jason rewrite sourceror spitfire ];
      };

    inflex =
      let
        version = "2.1.0";
      in
      buildMix {
        inherit version;
        name = "inflex";

        src = fetchHex {
          inherit version;
          pkg = "inflex";
          sha256 = "14c17d05db4ee9b6d319b0bff1bdf22aa389a25398d1952c7a0b5f3d93162dd8";
        };
      };

    iterex =
      let
        version = "0.1.2";
      in
      buildMix {
        inherit version;
        name = "iterex";

        src = fetchHex {
          inherit version;
          pkg = "iterex";
          sha256 = "2e103b8bcc81757a9af121f6dc0df312c9a17220f302b1193ef720460d03029d";
        };
      };

    jason =
      let
        version = "1.4.4";
      in
      buildMix {
        inherit version;
        name = "jason";

        src = fetchHex {
          inherit version;
          pkg = "jason";
          sha256 = "c5eb0cab91f094599f94d55bc63409236a8ec69a21a67814529e8d5f6cc90b3b";
        };

        beamDeps = [ decimal ];
      };

    libgraph =
      let
        version = "0.16.0";
      in
      buildMix {
        inherit version;
        name = "libgraph";

        src = fetchHex {
          inherit version;
          pkg = "libgraph";
          sha256 = "41ca92240e8a4138c30a7e06466acc709b0cbb795c643e9e17174a178982d6bf";
        };
      };

    mime =
      let
        version = "2.0.6";
      in
      buildMix {
        inherit version;
        name = "mime";

        src = fetchHex {
          inherit version;
          pkg = "mime";
          sha256 = "c9945363a6b26d747389aac3643f8e0e09d30499a138ad64fe8fd1d13d9b153e";
        };
      };

    mint =
      let
        version = "1.6.2";
      in
      buildMix {
        inherit version;
        name = "mint";

        src = fetchHex {
          inherit version;
          pkg = "mint";
          sha256 = "5ee441dffc1892f1ae59127f74afe8fd82fda6587794278d924e4d90ea3d63f9";
        };

        beamDeps = [ castore hpax ];
      };

    nimble_options =
      let
        version = "1.1.1";
      in
      buildMix {
        inherit version;
        name = "nimble_options";

        src = fetchHex {
          inherit version;
          pkg = "nimble_options";
          sha256 = "821b2470ca9442c4b6984882fe9bb0389371b8ddec4d45a9504f00a66f650b44";
        };
      };

    nimble_pool =
      let
        version = "1.1.0";
      in
      buildMix {
        inherit version;
        name = "nimble_pool";

        src = fetchHex {
          inherit version;
          pkg = "nimble_pool";
          sha256 = "af2e4e6b34197db81f7aad230c1118eac993acc0dae6bc83bac0126d4ae0813a";
        };
      };

    owl =
      let
        version = "0.12.0";
      in
      buildMix {
        inherit version;
        name = "owl";

        src = fetchHex {
          inherit version;
          pkg = "owl";
          sha256 = "241d85ae62824dd72f9b2e4a5ba4e69ebb9960089a3c68ce6c1ddf2073db3c15";
        };
      };

    phoenix =
      let
        version = "1.7.14";
      in
      buildMix {
        inherit version;
        name = "phoenix";

        src = fetchHex {
          inherit version;
          pkg = "phoenix";
          sha256 = "c7859bc56cc5dfef19ecfc240775dae358cbaa530231118a9e014df392ace61a";
        };

        beamDeps = [ castore jason phoenix_pubsub phoenix_template phoenix_view plug plug_crypto telemetry websock_adapter ];
      };

    phoenix_ecto =
      let
        version = "4.6.2";
      in
      buildMix {
        inherit version;
        name = "phoenix_ecto";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_ecto";
          sha256 = "3f94d025f59de86be00f5f8c5dd7b5965a3298458d21ab1c328488be3b5fcd59";
        };

        beamDeps = [ ecto phoenix_html plug postgrex ];
      };

    phoenix_html =
      let
        version = "4.1.1";
      in
      buildMix {
        inherit version;
        name = "phoenix_html";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_html";
          sha256 = "f2f2df5a72bc9a2f510b21497fd7d2b86d932ec0598f0210fed4114adc546c6f";
        };
      };

    phoenix_live_dashboard =
      let
        version = "0.8.4";
      in
      buildMix {
        inherit version;
        name = "phoenix_live_dashboard";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_live_dashboard";
          sha256 = "2984aae96994fbc5c61795a73b8fb58153b41ff934019cfb522343d2d3817d59";
        };

        beamDeps = [ ecto mime phoenix_live_view telemetry_metrics ];
      };

    phoenix_live_view =
      let
        version = "0.20.17";
      in
      buildMix {
        inherit version;
        name = "phoenix_live_view";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_live_view";
          sha256 = "a61d741ffb78c85fdbca0de084da6a48f8ceb5261a79165b5a0b59e5f65ce98b";
        };

        beamDeps = [ floki jason phoenix phoenix_html phoenix_template phoenix_view plug telemetry ];
      };

    phoenix_pubsub =
      let
        version = "2.1.3";
      in
      buildMix {
        inherit version;
        name = "phoenix_pubsub";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_pubsub";
          sha256 = "bba06bc1dcfd8cb086759f0edc94a8ba2bc8896d5331a1e2c2902bf8e36ee502";
        };
      };

    phoenix_template =
      let
        version = "1.0.4";
      in
      buildMix {
        inherit version;
        name = "phoenix_template";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_template";
          sha256 = "2c0c81f0e5c6753faf5cca2f229c9709919aba34fab866d3bc05060c9c444206";
        };

        beamDeps = [ phoenix_html ];
      };

    phoenix_view =
      let
        version = "2.0.4";
      in
      buildMix {
        inherit version;
        name = "phoenix_view";

        src = fetchHex {
          inherit version;
          pkg = "phoenix_view";
          sha256 = "4e992022ce14f31fe57335db27a28154afcc94e9983266835bb3040243eb620b";
        };

        beamDeps = [ phoenix_html phoenix_template ];
      };

    picosat_elixir =
      let
        version = "0.2.3";
      in
      buildMix {
        inherit version;
        name = "picosat_elixir";

        src = fetchHex {
          inherit version;
          pkg = "picosat_elixir";
          sha256 = "f76c9db2dec9d2561ffaa9be35f65403d53e984e8cd99c832383b7ab78c16c66";
        };

        beamDeps = [ elixir_make ];
      };

    plug =
      let
        version = "1.16.1";
      in
      buildMix {
        inherit version;
        name = "plug";

        src = fetchHex {
          inherit version;
          pkg = "plug";
          sha256 = "a13ff6b9006b03d7e33874945b2755253841b238c34071ed85b0e86057f8cddc";
        };

        beamDeps = [ mime plug_crypto telemetry ];
      };

    plug_crypto =
      let
        version = "2.1.0";
      in
      buildMix {
        inherit version;
        name = "plug_crypto";

        src = fetchHex {
          inherit version;
          pkg = "plug_crypto";
          sha256 = "131216a4b030b8f8ce0f26038bc4421ae60e4bb95c5cf5395e1421437824c4fa";
        };
      };

    postgrex =
      let
        version = "0.19.1";
      in
      buildMix {
        inherit version;
        name = "postgrex";

        src = fetchHex {
          inherit version;
          pkg = "postgrex";
          sha256 = "8bac7885a18f381e091ec6caf41bda7bb8c77912bb0e9285212829afe5d8a8f8";
        };

        beamDeps = [ db_connection decimal jason ];
      };

    reactor =
      let
        version = "0.10.0";
      in
      buildMix {
        inherit version;
        name = "reactor";

        src = fetchHex {
          inherit version;
          pkg = "reactor";
          sha256 = "4003c33e4c8b10b38897badea395e404d74d59a31beb30469a220f2b1ffe6457";
        };

        beamDeps = [ igniter iterex libgraph spark splode telemetry ];
      };

    req =
      let
        version = "0.5.6";
      in
      buildMix {
        inherit version;
        name = "req";

        src = fetchHex {
          inherit version;
          pkg = "req";
          sha256 = "cfaa8e720945d46654853de39d368f40362c2641c4b2153c886418914b372185";
        };

        beamDeps = [ finch jason mime plug ];
      };

    rewrite =
      let
        version = "0.10.5";
      in
      buildMix {
        inherit version;
        name = "rewrite";

        src = fetchHex {
          inherit version;
          pkg = "rewrite";
          sha256 = "51cc347a4269ad3a1e7a2c4122dbac9198302b082f5615964358b4635ebf3d4f";
        };

        beamDeps = [ glob_ex sourceror ];
      };

    sourceror =
      let
        version = "1.6.0";
      in
      buildMix {
        inherit version;
        name = "sourceror";

        src = fetchHex {
          inherit version;
          pkg = "sourceror";
          sha256 = "e90aef8c82dacf32c89c8ef83d1416fc343cd3e5556773eeffd2c1e3f991f699";
        };
      };

    spark =
      let
        version = "2.2.32";
      in
      buildMix {
        inherit version;
        name = "spark";

        src = fetchHex {
          inherit version;
          pkg = "spark";
          sha256 = "ee5a0a4ddb16ad8f5a792a7b1883498d3090c60101af77a866f76d54962478e8";
        };

        beamDeps = [ igniter jason sourceror ];
      };

    spitfire =
      let
        version = "0.1.3";
      in
      buildMix {
        inherit version;
        name = "spitfire";

        src = fetchHex {
          inherit version;
          pkg = "spitfire";
          sha256 = "d53b5107bcff526a05c5bb54c95e77b36834550affd5830c9f58760e8c543657";
        };
      };

    splode =
      let
        version = "0.2.4";
      in
      buildMix {
        inherit version;
        name = "splode";

        src = fetchHex {
          inherit version;
          pkg = "splode";
          sha256 = "ca3b95f0d8d4b482b5357954fec857abd0fa3ea509d623334c1328e7382044c2";
        };
      };

    stream_data =
      let
        version = "1.1.2";
      in
      buildMix {
        inherit version;
        name = "stream_data";

        src = fetchHex {
          inherit version;
          pkg = "stream_data";
          sha256 = "129558d2c77cbc1eb2f4747acbbea79e181a5da51108457000020a906813a1a9";
        };
      };

    swoosh =
      let
        version = "1.17.2";
      in
      buildMix {
        inherit version;
        name = "swoosh";

        src = fetchHex {
          inherit version;
          pkg = "swoosh";
          sha256 = "de914359f0ddc134dc0d7735e28922d49d0503f31e4bd66b44e26039c2226d39";
        };

        beamDeps = [ bandit finch jason mime plug req telemetry ];
      };

    tailwind =
      let
        version = "0.2.3";
      in
      buildMix {
        inherit version;
        name = "tailwind";

        src = fetchHex {
          inherit version;
          pkg = "tailwind";
          sha256 = "8e45e7a34a676a7747d04f7913a96c770c85e6be810a1d7f91e713d3a3655b5d";
        };

        beamDeps = [ castore ];
      };

    telemetry =
      let
        version = "1.3.0";
      in
      buildRebar3 {
        inherit version;
        name = "telemetry";

        src = fetchHex {
          inherit version;
          pkg = "telemetry";
          sha256 = "7015fc8919dbe63764f4b4b87a95b7c0996bd539e0d499be6ec9d7f3875b79e6";
        };
      };

    telemetry_metrics =
      let
        version = "0.6.2";
      in
      buildMix {
        inherit version;
        name = "telemetry_metrics";

        src = fetchHex {
          inherit version;
          pkg = "telemetry_metrics";
          sha256 = "9b43db0dc33863930b9ef9d27137e78974756f5f198cae18409970ed6fa5b561";
        };

        beamDeps = [ telemetry ];
      };

    telemetry_poller =
      let
        version = "1.1.0";
      in
      buildRebar3 {
        inherit version;
        name = "telemetry_poller";

        src = fetchHex {
          inherit version;
          pkg = "telemetry_poller";
          sha256 = "9eb9d9cbfd81cbd7cdd24682f8711b6e2b691289a0de6826e58452f28c103c8f";
        };

        beamDeps = [ telemetry ];
      };

    thousand_island =
      let
        version = "1.3.5";
      in
      buildMix {
        inherit version;
        name = "thousand_island";

        src = fetchHex {
          inherit version;
          pkg = "thousand_island";
          sha256 = "2be6954916fdfe4756af3239fb6b6d75d0b8063b5df03ba76fd8a4c87849e180";
        };

        beamDeps = [ telemetry ];
      };

    websock =
      let
        version = "0.5.3";
      in
      buildMix {
        inherit version;
        name = "websock";

        src = fetchHex {
          inherit version;
          pkg = "websock";
          sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
        };
      };

    websock_adapter =
      let
        version = "0.5.7";
      in
      buildMix {
        inherit version;
        name = "websock_adapter";

        src = fetchHex {
          inherit version;
          pkg = "websock_adapter";
          sha256 = "d0f478ee64deddfec64b800673fd6e0c8888b079d9f3444dd96d2a98383bdbd1";
        };

        beamDeps = [ bandit plug websock ];
      };
  };
in
self
