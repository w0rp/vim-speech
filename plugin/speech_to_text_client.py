#!plugin/venv/bin/python
from __future__ import absolute_import, print_function, unicode_literals

import os
import select
import sys
import wave
import signal
from io import BytesIO

import pyaudio

SAMPLE_RATE = 16000
CHANNELS = 1
CHUNK_SIZE = 1024
AUDIO_FORMAT = pyaudio.paInt16


def print_and_flush(*args, **kwargs):
    """
    print() doesn't flush, and we need to flush for the Vim plugin to work.
    """
    print(*args, **kwargs)
    sys.stdout.flush()


class RecordingClient(object):
    def __init__(self):
        self.frames = []
        self.audio_context = None
        self.stream = None
        self.signit_sent = False

    def trap_sigint(self):
        def signal_handler(*args, **kwargs):
            self.signit_sent = True

        signal.signal(signal.SIGINT, signal_handler)

    def start_recording(self):
        self.frames = []

        self.audio_context = pyaudio.PyAudio()
        self.stream = self.audio_context.open(
            format=AUDIO_FORMAT,
            channels=CHANNELS,
            rate=SAMPLE_RATE,
            input=True,
            frames_per_buffer=CHUNK_SIZE,
        )

    def save_frames(self):
        if self.stream is not None:
            data = self.stream.read(CHUNK_SIZE)
            self.frames.append(data)

    def cleanup(self):
        if self.stream is not None:
            self.stream.stop_stream()
            self.stream.close()
            self.stream = None

        if self.audio_context is not None:
            self.audio_context.terminate()

        self.frames = []

    def stop_recording(self):
        if (
            self.stream is None
            or self.audio_context is None
            or not self.frames
        ):
            return b''

        self.stream.stop_stream()
        self.stream.close()
        self.audio_context.terminate()

        output_file = BytesIO()

        wf = wave.open(output_file, 'wb')
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(self.audio_context.get_sample_size(AUDIO_FORMAT))
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(b''.join(self.frames))
        wf.close()

        self.stream = None
        self.audio_context = None
        self.frames = []

        return output_file.getvalue()


def transcribe_file(content):
    from google.cloud import speech
    from google.cloud.speech import enums
    from google.cloud.speech import types

    if not content:
        return ''

    client = speech.SpeechClient()

    audio = types.RecognitionAudio(content=content)
    config = types.RecognitionConfig(
        encoding=enums.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=SAMPLE_RATE,
        language_code='en-US',
    )

    response = client.recognize(config, audio)
    lines = []

    for result in response.results:
        lines.append(result.alternatives[0].transcript)

    return ' '.join(lines)


def stdin_has_data():
    try:
        return sys.stdin in select.select([sys.stdin], [], [], 0)[0]
    except select.error:
        return False


def main():
    # Stop early if the environment variable isn't set.
    if not os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
        sys.exit(
            'You must set GOOGLE_APPLICATION_CREDENTIALS'
            ' to your JSON credentials filename.'
        )

    client = RecordingClient()
    client.trap_sigint()

    while True:
        if client.signit_sent:
            break

        if stdin_has_data():
            line = sys.stdin.readline()

            if line:
                message = line.lower().strip()

                if client.signit_sent:
                    break

                if message == 'record':
                    print_and_flush('record start')
                    client.start_recording()
                elif message == 'stop':
                    print_and_flush('record end')
                    audio_content = client.stop_recording()
                    print_and_flush('speech', transcribe_file(audio_content))
                elif message == 'quit':
                    break

        client.save_frames()

    if client.signit_sent:
        # Print a line if we caught SIGINT, for the benefit of terminals.
        print_and_flush()

    client.cleanup()


if __name__ == "__main__":
    main()
