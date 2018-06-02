# vim-speech

This project is an attempt at getting some basic speech to text processing
working in Vim using Google's cloud services. This project is a proof of
concept.

This project uses an MIT licence to allow you to basically do what you want.

## Installation

Run `./install.sh` from the project directory to install everything from your
Terminal.  This will only work on Debian on Ubuntu. For installation on other
machines, read the script and try to figure it out.

## Usage so far

Run the script from a terminal where your `GOOGLE_APPLICATION_CREDENTIALS`
environment variable is set. For example:

```bash
# ~/whatever.json won't work, so use $HOME/whatever.json.
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/whatever.json"
```

Run `arecord -f S16 -r 16000 ~/test.wav` to record a voice sample to read.
Run `./test.py` to get the speech from the test file.

`arecord` might not record anything. Mess around with `pavucontrol` and select
different audio devices if that happens, because you're probably using the wrong
one.
