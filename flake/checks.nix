# Copyright (c) 2025 Ergon Informatik AG
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
{
  inputs,
  config,
  ...
}: let
  mkShell = config.flake.lib.mkShell;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    checks = let
      checkTemplate = name: fakeInputs: let
        template = import ../templates/${name}/flake.nix;
        outputs = template.outputs (fakeInputs
          // {
            self = outputs // {inputs = fakeInputs;};
          });
        shell = outputs.devShells.${system}.default;
      in
        pkgs.runCommand "template-${name}-check" {} ''
          test -e ${shell}
          touch $out
        '';
    in {
      mk-shell = let
        shell = mkShell {inherit pkgs;} {
          packages = [pkgs.hello];
        };
      in
        pkgs.runCommand "mk-shell-check" {
          nativeBuildInputs = shell.nativeBuildInputs;
        } ''
          # Ensure the shell derivation itself builds
          test -e ${shell}
          # Verify packages from the shell are available
          hello > $out
        '';

      template-default =
        checkTemplate
        "nix-shell-parts"
        {
          inherit (inputs) nixpkgs flake-parts;
          nix-shell-parts = inputs.self;
        };
    };
  };
}
