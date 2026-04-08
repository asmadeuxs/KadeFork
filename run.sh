#!/bin/bash

echo
echo "| Formatting Source Code files |"
echo

haxelib run formatter -s source

echo
echo "Formatting built-in modded scripts (if any.)"
echo

haxelib run formatter -s assets

echo
echo "Compiling..."
echo

haxelib run lime test cpp -debug