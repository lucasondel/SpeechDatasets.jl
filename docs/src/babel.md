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
