# MASS dataset

The data's project is located [here](https://github.com/getalp/mass-dataset)

## Installing the corpus

The data should be downloaded
[here](https://www.faithcomesbyhearing.com/audio-bible-resources/mp3-downloads).

Make sure to download the correct data:

| Language | Archive Name      |
|:---------|:------------------|
| basque   | EUSEABN1DA.zip    |
| english  | ENGESVN1DA.zip    |
| finnish  | FIN38VN1DA.zip    |
| french   | FRNTLSN2DA.zip    |
| hungarian| HUNHBSN1DA.zip    |
| romanian | RONDCVN1DA.zip    |
| russian  | RUSS76N2DA.zip    |

Then, un-zip the archive and run:

```julia
using SpeechDatasets

MASSDATASET.prepare("data/mass", "audioddi", lang)
```
where `audiodir` is the directory containing the MP3 files, lang is
the name of the language (`:french`, `:basque`, `:russian`, ...).

## Citation
```
@inproceedings{boito2020mass,
    title={MaSS: A Large and Clean Multilingual Corpus of Sentence-aligned Spoken Utterances Extracted from the Bible},
    author={Marcely Zanon Boito and William N. Havard and Mahault Garnerin and Éric Le Ferrand and Laurent Besacier},
    booktitle = {Language Resources and Evaluation Conference (LREC) 2020},
   year={2020},
 }
```

