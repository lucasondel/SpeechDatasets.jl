# TIMIT corpus

The famous TIMIT corpus, equivalent of MNIST in speech recognition.
This corpus is part of the LDC catalogue and can be downloaded
[here](https://catalog.ldc.upenn.edu/LDC93S1).

## Installing the corpus

```julia
using SpeechDatasets

TIMIT.prepare("data/timit", "timit/root/dir")
```

!!! warning
    the preparation function assumes that the directory are lower-case!

## Citation

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

