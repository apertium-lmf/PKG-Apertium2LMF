PKG-Apertium2LMF
================

This tool generates the LMF version of Apertium monolingual lexicons. The script takes as input an expanded monolingual Apertium lexicon (generated using: lt-expand apertium.dix > apertium.expanded) and generates the corresponding LMF version. In the Apertium expended lexicons, the first tag corresponds to the part of speech. The rest of tags (all enclosed in angle brackets) encode additional information depending on the lemma and PoS tag. Run "perl ApertiumMonolingual2LMF.pl --help" to get more information.

The tool was downloaded from http://repositori.upf.edu/handle/10230/17128

Copyright
=========

Copyright 2012 Universitat Pompeu Fabra. Institut Universitari de Lingüística Aplicada (IULA)
CC-BY-SA 3.0
