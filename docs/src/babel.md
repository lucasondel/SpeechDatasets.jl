# Babel corpus

Data released from the IARPA project. The corpus is part of the
LDC catalogue and can be downloaded [here](https://catalog.ldc.upenn.edu/search).

## Installing the corpus

The corpus is composed for several languages. Here is an example to
install the data of one language.
```julia
using SpeechDatasets

BABEL.prepare("data/babel/cantonese", "path/to/BABEL_BP_101/conversational")
```

!!! note
    The script will only prepare the training and the development
    set.

## Citation

The citation is language dependent and need to be taken from the LDC
website.

```
@article{garofolo1993darpa,
  title={DARPA TIMIT acoustic-phonetic continous speech corpus CD-ROM. NIST speech disc 1-1.1},
  author={Garofolo, John S and Lamel, Lori F and Fisher, William M and Fiscus, Jonathan G and Pallett, David S},
  journal={NASA STI/Recon technical report n},
  volume={93},
  pages={27403},
  year={1993}
}
```
