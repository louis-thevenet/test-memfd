{
  stdenv-glibc,
  pkgs,
  ...
}:
pkgs.python311.pkgs.buildPythonApplication {
  pname = "slapos";
  version = "1.16.3";
  sdtenv = stdenv-glibc;
  format = "pyproject";

  src = pkgs.fetchFromGitLab {
    owner = "louis.thevenet";
    repo = "slapos.core";
    domain = "lab.nexedi.com";
    rev = "5258974b6d7f";
    # rev = "04aadf0615a0"; # PEP 625 fix: https://lab.nexedi.com/nexedi/slapos.buildout/-/merge_requests/43
    hash = "sha256-IEtvu7KvTyTkFWkeXUViBrjjvwRIalOdMyYGOUYD9gE=";
  };

  propagatedBuildInputs =
    let
      zc-buildout = (
        pkgs.python311Packages.buildPythonPackage {
          pname = "zc.buildout";
          pyproject = true;

          version = "3.0.1+slapos010";
          src = pkgs.fetchFromGitLab {
            # owner = "xavier_thompson";
            owner = "louis.thevenet";
            repo = "slapos.buildout";
            domain = "lab.nexedi.com";
            rev = "a8ad1e3bf6ee";
            # rev = "04aadf0615a0"; # PEP 625 fix: https://lab.nexedi.com/nexedi/slapos.buildout/-/merge_requests/43
            hash = "sha256-/+5yL3QTR3zIHUXUyq25RWrrGN1/qAYMykWHtG/Rm8Y=";
          };

          build-system = with pkgs.python311Packages; [ setuptools ];

          dependencies = with pkgs.python311Packages; [
            # TODO: Patch buildout fork so it supports pip >= 23.2.1
            #  File "zc/buildout/patches.py", line 66, in patch_PackageIndex
            # from pip._vendor import six
            # ImportError: cannot import name 'six' from 'pip._vendor
            (pip.overrideAttrs (oldAttrs: rec {
              pname = "pip";
              version = "23.2.1";
              src = pkgs.fetchFromGitHub {
                owner = "pypa";
                repo = pname;
                rev = version;
                hash = "sha256-mUlzfYmq1FE3X1/2o7sYJzMgwHRI4ib4EMhpg83VvrI=";
              };
            }))
          ];
          doCheck = false; # Missing package & BLOCKED on "zc.recipe.egg"
          pythonImportsCheck = [ "zc.buildout" ];
          pythonNamespaces = [ "zc" ];
        }
      );
      libnetworkcache = pkgs.python311Packages.buildPythonPackage rec {
        pname = "libnetworkcache";
        version = "0.28";
        src = pkgs.fetchFromGitLab {
          owner = "nexedi";
          repo = "slapos.libnetworkcache";
          domain = "lab.nexedi.com";
          rev = version;
          hash = "sha256-xjfob//vHMG3WJewCSZYZmblOQFP/gy5L99IJ0CCD8A=";
        };
        nativeCheckInputs = with pkgs; [ openssl ];
        propagatedBuildInputs = with pkgs; [ openssl ];
      };
    in
    [
      zc-buildout
      libnetworkcache
    ]
    ++ (with pkgs.python311Packages; [

      # (buildPythonPackage {
      #   pname = "zc-recipe-egg";
      #   pyproject = true;

      #   version = "2.0.8.dev0+slapos010";
      #   src = pkgs.fetchFromGitLab {
      #     owner = "nexedi";
      #     repo = "slapos.buildout";
      #     domain = "lab.nexedi.com";
      #     rev = "3.0.1+slapos010";
      #     hash = "sha256-gWmPa3jzhy3RsWZ0j21JHWloRB4PbBnRLZBA8hlxuYI=";
      #   };
      #   sourceRoot = "source/zc.recipe.egg_";
      #   build-system = with pkgs.python311Packages; [ setuptools ];

      #   dependencies = [ zc-buildout ];
      #   pythonImportsCheck = [ "zc.recipe.egg" ];
      #   pythonNamespaces = [ "zc.recipe" ];

      # })
      wheel
      flask
      (lxml.override { stdenv = stdenv-glibc; })
      netaddr
      netifaces
      (supervisor.override { stdenv = stdenv-glibc; })
      (psutil.override { stdenv = stdenv-glibc; })
      xml-marshaller
      zope_interface
      cliff
      (requests.override { stdenv = stdenv-glibc; })
      six
      cachecontrol
      jsonschema
      pyyaml
      uritemplate
      distro
      cachecontrol
      filelock
    ]);
}
