#!/bin/bash

jflex cool.lex
javac -cp ../../lib/ -d build/ *.java
java -cp ../../lib/:build/ Lexer $1