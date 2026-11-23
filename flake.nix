{
  description = "xmonad in Bend: xmonad 0.18.1's StackSet, Layout and window manager, with laws and differential tests against xmonad itself";

  # bend-frp's pinned Bend (2.0.39), with BendTT's kernel built in, so
  # `bend PROOF.bend --verdict` works; the same Bend directo-bend and
  # mugen-app build with
  inputs.bend-frp.url = "github:hhefesto/bend-frp";
  inputs.nixpkgs.follows = "bend-frp/nixpkgs";
  # xmonad's own source: the reference the differential tests ask
  inputs.xmonad = {
    url = "github:xmonad/xmonad/v0.18.1";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      bend-frp,
      xmonad,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      each = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
      lib = nixpkgs.lib;
      # What a build sees: the Bend modules and the C side of X.bend
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          (lib.fileset.fileFilter (f: f.hasExt "bend") ./.)
          ./x11.c
          ./tests
        ];
      };
      bendFor = pkgs: bend-frp.packages.${pkgs.stdenv.hostPlatform.system}.bend;
      # x11.c's headers and library, for the C compiler bend runs (its
      # wrapper reads the flags under the platform's suffix)
      x11Flags = pkgs: ''
        export NIX_CFLAGS_COMPILE_${pkgs.stdenv.cc.suffixSalt}="-I${pkgs.libx11.dev}/include -I${pkgs.xorgproto}/include"
        export NIX_LDFLAGS_${pkgs.stdenv.cc.suffixSalt}="-L${pkgs.libx11}/lib -rpath ${pkgs.libx11}/lib"
      '';
      # GHC with what xmonad needs, and QuickCheck for the generators
      ghcFor =
        pkgs:
        pkgs.haskellPackages.ghcWithPackages (
          p: with p; [
            X11
            QuickCheck
            containers
            data-default-class
            directory
            filepath
            mtl
            process
            setlocale
            time
            transformers
            unix
          ]
        );
      # the end-to-end tools: xmonad itself (default config), the test
      # client and the snapshot
      e2eFor =
        pkgs:
        pkgs.runCommand "xmonad-bend-e2e-tools" { nativeBuildInputs = [ (ghcFor pkgs) ]; } ''
          mkdir -p $out/bin o
          cp -r ${src}/tests t
          chmod -R u+w t
          ghc -O1 -i${xmonad}/src -it/e2e/ref -outputdir o/ref -o $out/bin/xmonad-ref t/e2e/Ref.hs
          ghc -O0 -outputdir o/client -o $out/bin/e2e-client t/e2e/Client.hs
          ghc -O0 -outputdir o/snap -o $out/bin/e2e-snap t/e2e/Snap.hs
        '';
      inSource =
        pkgs: name: inputs: script:
        pkgs.runCommand "xmonad-bend-${name}" { nativeBuildInputs = [ (bendFor pkgs) ] ++ inputs; } ''
          export HOME=$TMPDIR
          cp -r ${src} w
          chmod -R u+w w
          cd w
          ${script}
        '';
    in
    {
      packages = each (
        system: pkgs: {
          default = self.packages.${system}.xmonad-bend;
          xmonad-bend = inSource pkgs "wm" [ ] ''
            ${x11Flags pkgs}
            mkdir -p $out/bin
            bend Main.bend -o $out/bin/xmonad-bend
          '';
          ghc-xmonad = ghcFor pkgs;
          e2e-tools = e2eFor pkgs;
          bend = bendFor pkgs;
        }
      );

      checks = each (
        system: pkgs: {
          # the laws hold: Bend's checker, then BendTT's kernel
          proofs = inSource pkgs "proofs" [ ] ''
            bend PROOF.bend --verdict 2>&1 | tee $out
            grep -q 'ALL PROOFS CHECK' $out
          '';
          # every pure module checks (Main and X use X11's effects, so a check
          # names them; it must name nothing else)
          modules = inSource pkgs "modules" [ ] ''
            for f in Num StackSet Layout Core Operations; do
              bend $f.bend --check-only 2>&1 | tee -a $out | grep -q 'ALL PROOFS CHECK'
            done
          '';
          # each mutant of StackSet.bend and Layout.bend makes PROOF.bend fail
          mutants = inSource pkgs "mutants" [ pkgs.zsh ] ''
            BEND=$(command -v bend) zsh tests/mutants.sh 2>&1 | tee $out
          '';
        }
      );

      devShells = each (
        system: pkgs: {
          default = pkgs.mkShell {
            packages = [
              (bendFor pkgs)
              (ghcFor pkgs)
              pkgs.xvfb
              pkgs.xdotool
              pkgs.zsh
            ];
            shellHook = ''
              ${x11Flags pkgs}
              export XMONAD=${xmonad}
            '';
          };
        }
      );
    };
}
