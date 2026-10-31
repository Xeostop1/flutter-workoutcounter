@echo off
set "ANDROID_HOME=C:\Users\hns\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\hns\AppData\Local\Android\Sdk"
"C:\Users\hns\AppData\Local\Android\SPORKLE-Audio-SDK-20261031\emulator\emulator.exe" -avd SPORKLE_Android15_AudioCheck -port 5572 -sysdir "C:\Users\hns\AppData\Local\Android\Sdk\system-images\android-35\google_apis\x86_64" -gpu host -no-boot-anim -no-snapshot-load -no-snapshot-save
