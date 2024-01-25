@echo off
set srcfile=.\excel-formulas.md
set out-html=.\excel-formulas.html

set pandoc_bin=%LOCALAPPDATA%\Pandoc\pandoc.exe
set filter_dir=%LOCALAPPDATA%\Pandoc\tools
set mermaid=%APPDATA%\npm\mermaid-filter.cmd

if exist "%out-html%" del "%out-html%"


:: create temporary markdown
"%pandoc_bin%" -F %mermaid% %srcfile% -s -t markdown -o tmp.md

:: create html output
"%pandoc_bin%" --mathjax --highlight-style=breezeDark tmp.md -s -t html -c .\water.css -o %out-html%
