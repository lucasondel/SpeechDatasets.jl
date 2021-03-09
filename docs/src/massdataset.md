# MASS dataset

The data's project is located [here](https://github.com/getalp/mass-dataset)

## Installing the corpus

The data should be downloaded
[here](https://www.faithcomesbyhearing.com/audio-bible-resources/mp3-downloads).

Make sure to download the correct data:

| Language | Language Name | Version                                    | Archive Name      |
|:---------|:--------------|:-------------------------------------------|:------------------|
| Basque   | Euskara       | Non Drama New Testament                    | EUSEABN1DA.zip    |
| English  | English       | Standard Version Non Drama New Testament   | ENGESVN1DA.zip    |
| Finnish  | Finnish       | 1938 New Testament Non Drama               | FIN38VN1DA.zip    |
| French   | French        | 1910 Louis Segond New Testament            | FRNTLSN2DA.zip    |
| Hungarian| Hungariance   | ?                                          | HUNHBSN1DA.zip    |
| Romanian | Romanian      | Dumitru Cornilescu Non Drama New Testament | RONDCVN1DA.zip    |
| Russian  | Russian       | 1876 Synodal Bible Drama New Testament     | RUSS76N2DA.zip    |

Then, un-zip the archive and run:

```julia
using SpeechDatasets

MASSDATASET.prepare("data/massdataset", "audiodir", "lang")
```
where `audiodir` is the directory containing the MP3 files, "lang" is
the name of the language of the data without capital (french, basque,
russian, ...).

## Citation
```
@inproceedings{boito2020mass,
    title={MaSS: A Large and Clean Multilingual Corpus of Sentence-aligned Spoken Utterances Extracted from the Bible},
    author={Marcely Zanon Boito and William N. Havard and Mahault Garnerin and Éric Le Ferrand and Laurent Besacier},
    booktitle = {Language Resources and Evaluation Conference (LREC) 2020},
   year={2020},
 }
```

