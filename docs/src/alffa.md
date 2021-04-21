# ALFFA corpus

The original corpus is located [here](https://github.com/besacier/mboshi-french-parallel-corpus/blob/master/README.md).  Note that you don't need to download it, the
preparation script will do it for you.

## Installing the corpus

```julia
using SpeechDatasets

ALFFA.prepare("data/alffa", :amharic | :swahili)
```

!!! note
    Currently, we only support Amharic and Swahili languages

## Citation

For amharic
```
@InProceedings {Abate2005,
	Author = {Solomon Teferra Abate and Wolfgang Menzel and Bairu Tafila},
	booktitle = {INTERSPEECH-2005},
	Title =  {An Amharic Speech Corpus for Large Vocabulary Continuous Speech Recognition},
	Year = {2005}
}
```

For Swahiliy
```
@InProceedings {gelas:hal-00954048,
	author = {Gelas, Hadrien and Besacier, Laurent and Pellegrino, Francois},
	title = {{D}evelopments of {S}wahili resources for an automatic speech recognition system},
	booktitle = {{SLTU} - {W}orkshop on {S}poken {L}anguage {T}echnologies for {U}nder-{R}esourced {L}anguages},
	year = {2012},
	address = {Cape-Town, Afrique Du Sud},
	abstract = {no abstract},
	x-international-audience = {yes},
	url = {http://hal.inria.fr/hal-00954048}
}
```

