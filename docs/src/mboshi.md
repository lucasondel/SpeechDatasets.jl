# Mboshi corpus

The original corpus is located [here](https://github.com/besacier/mboshi-french-parallel-corpus/blob/master/README.md). Note that you don't need to download it, the package will do it for you.

## Installing the corpus

```julia
using SpeechDatasets

MBOSHI.prepare("data/mboshi")
```

## Citation

```
@article{DBLP:journals/corr/abs-1710-03501,
  author    = {Pierre Godard and
               Gilles Adda and
               Martine Adda{-}Decker and
               Juan Benjumea and
               Laurent Besacier and
               Jamison Cooper{-}Leavitt and
               Guy{-}No{\"{e}}l Kouarata and
               Lori Lamel and
               H{\'{e}}l{\`{e}}ne Maynard and
               Markus M{\"{u}}ller and
               Annie Rialland and
               Sebastian St{\"{u}}ker and
               Fran{\c{c}}ois Yvon and
               Marcely Zanon Boito},
  title     = {A Very Low Resource Language Speech Corpus for Computational Language
               Documentation Experiments},
  journal   = {CoRR},
  volume    = {abs/1710.03501},
  year      = {2017},
  url       = {http://arxiv.org/abs/1710.03501},
  archivePrefix = {arXiv},
  eprint    = {1710.03501},
  timestamp = {Tue, 16 Jan 2018 11:17:17 +0100},
  biburl    = {https://dblp.org/rec/bib/journals/corr/abs-1710-03501},
  bibsource = {dblp computer science bibliography, https://dblp.org}
}
```

