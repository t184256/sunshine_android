cd android/app/libs
sudo python3 -m http.server 80 &
cd -

cd android
nix develop -c 'flutter build apk'
