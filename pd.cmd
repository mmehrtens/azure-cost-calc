@echo off
set mydir=%~dp0

set pandoc_bin=%LOCALAPPDATA%\Pandoc\pandoc.exe
set filter_dir=%LOCALAPPDATA%\Pandoc\tools
set mermaid=%APPDATA%\npm\mermaid-filter.cmd


pushd %mydir%
for %%s in (*.md) do "%pandoc_bin%" --mathjax --highlight-style=breezeDark %%s -s -t html -c .\water.css -o %%s.html

popd