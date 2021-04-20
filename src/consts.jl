# Lucas Ondel, 2021

# Set of standards labels used across corpora
const LABELS = Dict(
    :speechunit => "speech-unit",
    :nonspeechunit => "non-speech-unit",
    :sil => "<sil>",
    :unk => "<unk>",
)

# Standard file names
const LOCATIONS = Dict(
    :wavs => "wav.scp",
    :local => ".local",
    :lang => "lang",
    :speakers => "speakers",
    :utt2spk => "uttids_speakers",
    :uttids => "uttids",
    :ali => "ali",
    :trans => "trans",
    :words => "words",
    :units => "units",
    :lexicon => "lexicon",
)

# Non-speech units (silence, breath, ...)
const NON_SPEECH_UNITS = Set([
    LABELS[:sil],
    LABELS[:unk]
])
