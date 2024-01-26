@echo off
set srcfile=.\excel-formulas.md
set out_html=.\excel-formulas.html
set out_pdf=.\excel-formulas.pdf

set pandoc_bin=%LOCALAPPDATA%\Pandoc\pandoc.exe
set filter_dir=%LOCALAPPDATA%\Pandoc\tools
set mermaid=%APPDATA%\npm\mermaid-filter.cmd

if exist "%out-html%" del "%out-html%"


:: create html output
"%pandoc_bin%" --mathjax --highlight-style=breezeDark %srcfile% -s -t html -c .\water.css -o %out_html%
::"%pandoc_bin%" --pdf-engine=xelatex --mathjax -H .\header.sty -o %out_pdf% %srcfile%
