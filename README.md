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

Run `./speech_to_text_client.py` To start the speech-to-text client recording
audio. It uses a simple text protocol which accepts the following commands
as lines of input, in a case-insensitive manner.

| Command        | Description                                                |
| -------------- | ---------------------------------------------------------- |
| `record`       | Start recording audio.                                     |
| `stop`         | Stop recording audio, and get the text from Google.        |

The protocol will respond with the following lines.

| Response       | Description                                                |
| -------------- | ---------------------------------------------------------- |
| `record start` | Signals when recording stops.                              |
| `record stop`  | Signals when recording ends.                               |
| `speech ...`   | Text data returned from Google.                            |

The client will catch SIGINT and stop the client as soon as possible, in a safe
manner. Debug information may be written to stderr. The client won't work at all
on operating systems that aren't Unix-like.

Nothing might be coming out from the voice samples when you try to record
speech. If this happens, mess around with `pavucontrol` and select different
audio devices while recording is live. You're probably using the wrong audio
device.
