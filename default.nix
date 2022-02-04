{ pkgs ? import <nixpkgs> { } }:
with pkgs; with lib; with builtins;
let
  json = fromJSON (readFile ./package.json);
  pname = replaceChars [ "@" "/" ] [ "" "-" ] (head (attrNames json.dependencies));
  version = head (attrValues json.dependencies);
  nodedir = runCommand "nodedir" { } ''
    tar xvf ${nodejs.src}
    mv node-* $out
  '';
  modules = yarn2nix-moretea.mkYarnModules {
    pname = "${pname}-modules";
    inherit version;
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;
    pkgConfig.mdctl.buildInputs = [ nodePackages.node-pre-gyp nodePackages.node-gyp python3 pkg-config libsecret ];
    postBuild = "cd $out && npm rebuild --nodedir=${nodedir} keytar sqlite3";
  };
in
stdenv.mkDerivation {
  inherit pname version;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${modules}/node_modules/pkg/node_modules/.bin/mdctl $out/bin
  '';
}
