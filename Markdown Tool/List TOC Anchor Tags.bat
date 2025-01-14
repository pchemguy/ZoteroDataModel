@echo off

grep -Po "^^<a id=\S* class=.TOC #.*$" "%~1"
