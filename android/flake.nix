{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  };
  outputs = { self, nixpkgs, ... }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true; # <-- this is needed
          allowUnfree = true;
        };
      };
      # --- Android SDK Configuration ---
      # We use composeAndroidPackages to select specific components
      # to reduce download size.
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [ "36.0.0" ];
        platformVersions = [ "36" ];

        # includeCmdlineTools and includePlatformTools are true by default
        # when using composeAndroidPackages like this.
        # cmdline-tools will be the latest available.
        #
        # You can add other components if needed:
        # includeEmulator = true;
        # includeSystemImages = true;
        # systemImageTypes = [ "google_apis_playstore" ];
        # abiVersions = [ "x86_64" ]; # Ensure x86_64 system images are included
        includeNDK = true;
        ndkVersions = ["29.0.14206865"]; # specify the version from grande configs in your project
        cmakeVersions = [ "3.31.6" ]; # the same
      };
      androidSdk = androidComposition.androidsdk;

    in
    {
      devShells.${system}.default =
        with pkgs; mkShell rec {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          buildInputs = [
            gradle
            flutter329
            androidSdk
            jdk17
          ];

          shellHook = ''
            export CHROME_EXECUTABLE="/home/alex/.nix-profile/bin/chromium"
            export JAVA_HOME="${jdk17}/lib/openjdk"
            export PATH="$JAVA_HOME/bin:$PATH"
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export PATH="${androidSdk}/platform-tools:$PATH"
            export PATH="${androidSdk}/cmdline-tools/latest/bin:$PATH"
            # Add build-tools so we can use the Nix-packaged aapt2 instead of Maven’s
            export PATH="${androidSdk}/build-tools/36.0.0:$PATH"
            # Force AGP to use aapt2 from SDK/build-tools rather than Maven cache (fixes NixOS stub-ld issue)
            export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2 $GRADLE_OPTS"
          '';
        };
    };
}
