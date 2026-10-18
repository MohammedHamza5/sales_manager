@echo off
chcp 65001 > nul
dart run tools/publish_update.dart %*
